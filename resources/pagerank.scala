import org.apache.spark.sql.SparkSession
//import org.apache.spark.sql.functions._
import org.apache.spark.rdd.RDD
import scala.math.BigDecimal.RoundingMode


val spark = SparkSession.builder().appName("SimplePageRank").master("spark://main:7077").getOrCreate()
val sc = spark.sparkContext
sc.setLogLevel("ERROR")

val inputPath = "/datasets/terasort/pageranksap.csv"
val lines = sc.textFile(inputPath)

val edges: RDD[(String, String)] = lines
  .flatMap { line =>
    val trimmed = line.trim
    if (trimmed.isEmpty || trimmed.toLowerCase.startsWith("node")) {
      Iterator.empty
    } else {
      val parts = trimmed.split(",").map(_.trim)
      parts match {
        case Array(src, dst) if src.nonEmpty && dst.nonEmpty => Iterator.single((src, dst))
        case _ => Iterator.empty
      }
    }
  }
  .cache()

val nodes = edges
  .flatMap { case (src, dst) => Iterator(src, dst) }
  .distinct()
  .cache()

val nodeCount = nodes.count().toDouble

val groupedEdges = edges
  .groupByKey()
  .mapValues(_.toArray)

val links = nodes
  .map(node => (node, Array.empty[String]))
  .leftOuterJoin(groupedEdges)
  .mapValues { case (_, outsOpt) => outsOpt.getOrElse(Array.empty[String]) }
  .cache()

  val danglingNodes = links
  .filter { case (_, outs) => outs.isEmpty }
  .keys
  .collect()
  .toSet

val bcDangling = sc.broadcast(danglingNodes)

val damping = 0.85
val teleport = (1.0 - damping) / nodeCount
val tolerance = 1e-8
val maxIterations = 100

var ranks = nodes.map(node => (node, 1.0 / nodeCount)).cache()
var iteration = 0
var delta = Double.PositiveInfinity

while (iteration < maxIterations && delta > tolerance) {
  val danglingMass = ranks
    .filter { case (node, _) => bcDangling.value.contains(node) }
    .values
    .sum()

  val contributions = links
    .join(ranks)
    .flatMap { case (_, (outs, rank)) =>
      if (outs.isEmpty) Iterator.empty
      else outs.iterator.map(dst => (dst, rank / outs.length))
    }

  val incoming = nodes
    .map(node => (node, 0.0))
    .union(contributions)
    .reduceByKey(_ + _)

  val danglingShare = if (bcDangling.value.nonEmpty) danglingMass / nodeCount else 0.0

  val newRanks = incoming
    .mapValues(sum => teleport + damping * (sum + danglingShare))
    .cache()

  delta = ranks
    .join(newRanks)
    .values
    .map { case (oldRank, newRank) => math.abs(oldRank - newRank) }
    .sum()

  ranks.unpersist(blocking = false)
  ranks = newRanks
  iteration += 1
}

val output = ranks
    .map { case (node, rank) =>
    val rounded = BigDecimal(rank).setScale(3, RoundingMode.HALF_UP).toDouble
    (node.toInt, rounded)
  }
  .sortBy({ case (node, rank) => (-rank, node) })
  .collect()

output.foreach { case (node, rank) =>
  println(f"$node,$rank%.3f")
}

spark.stop()
System.exit(0)