import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.rdd.RDD

val spark = SparkSession.builder().appName("SimplePageRank").master("spark://main:7077").getOrCreate()
val sc = spark.sparkContext
sc.setLogLevel("ERROR")

val inputPath = "hdfs://main:9000/datasets/terasort/pageranksap.csv"

// Read CSV, skip header, parse edges
val lines = sc.textFile(inputPath)
val edges = lines
  .filter(line => !line.trim.toLowerCase.startsWith("node"))
  .map(_.split(","))
  .map(arr => (arr(0).trim, arr(1).trim))

for line in lines.take(5) do println(line)

// Build adjacency and helpers
val links      = edges.groupByKey().mapValues(_.toArray).cache()   // (src, Array[dst])
val outNodes   = links.keys.cache()
val dangling   = allNodes.subtract(outNodes).cache()               // nodes with no outlinks
val bcDangling = sc.broadcast(dangling.collect().toSet)

val d  = 0.85
val tp = (1.0 - d) / N.toDouble
val eps = 1e-4
val maxIter = 100

var ranks = allNodes.map(n => (n, 1.0 / N)).cache()
var iter = 0
var converged = false

while (!converged && iter < maxIter) {
  // contributions from non-dangling nodes
  val contribs = links.join(ranks).flatMap { case (src, (outs, r)) =>
    val L = outs.length
    outs.iterator.map(dst => (dst, r / L))
  }

  // mass from dangling nodes
  val danglingMass = ranks.filter { case (n, _) => bcDangling.value(n) }
                          .values.sum()

  // sum inbound contributions for EVERY node (ensure nodes with no inbound get 0)
  val summed = allNodes.map(n => (n, 0.0)).union(contribs).reduceByKey(_ + _)

  // teleport + damping + redistributed dangling mass
  val newRanks = summed.mapValues(c => tp + d * (c + danglingMass / N)).cache()

  // L1 diff for convergence
  val diff = ranks.join(newRanks).values.map { case (a, b) => math.abs(a - b) }.sum()
  converged = diff < eps

  ranks.unpersist(false)
  ranks = newRanks
  iter += 1
}

val output = ranks
  .map{case (node, rank) => (node.toInt, BigDecimal(rank).setScale(3, BigDecimal.RoundingMode.HALF_UP).toDouble)}
  .sortBy({case (node, rank) => (-rank, node)})
  .collect()

output.foreach{ case (node, rank) =>
  println(f"$node,${rank}%.3f")
}

spark.stop()
System.exit(0)
