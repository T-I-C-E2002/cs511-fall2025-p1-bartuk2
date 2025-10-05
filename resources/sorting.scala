import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

// Create the SparkSession properly
val spark = SparkSession
  .builder()
  .appName("CapTeraSorting")
  .master("spark://main:7077")
  .getOrCreate()

val sc = spark.sparkContext
sc.setLogLevel("ERROR")

val inputPath = "hdfs://main:9000/datasets/terasort/samplecap.csv"

val rawDf = spark.read
  .option("header", "true")
  .option("inferSchema", "false")
  .csv(inputPath)

// Trim all column names to remove leading/trailing whitespace
val trimmedCols = rawDf.columns.map(_.trim)
val df = rawDf.toDF(trimmedCols: _*)

//rawDf.printSchema()
//rawDf.show(5)

val result = df
  .select(trim(col("year")).as("year"), trim(col("serial")).as("serial"))
  .withColumn("year_int", col("year").cast("int"))
  .filter(col("year_int").isNotNull && col("year_int") <= 2025)
  .orderBy(col("year_int").desc, col("serial").asc) // changed to ascending
  .select(concat_ws(",", col("year"), col("serial")).as("value"))

// Output only the sorted results, one per line, no extra output
result.collect().foreach(r => println(r.getString(0)))

spark.stop()
System.exit(0)