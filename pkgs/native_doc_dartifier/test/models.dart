import 'package:objectbox/objectbox.dart';

@Entity()
class ClassSummaryModel {
  @Id()
  int id = 0;

  String summary;

  @HnswIndex(dimensions: 3072, distanceType: VectorDistanceType.euclidean)
  @Property(type: PropertyType.floatVector)
  List<double> embeddings;

  ClassSummaryModel(this.summary, this.embeddings);
}
