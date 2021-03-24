import 'package:line_break/properties/line_break_property.dart';
import 'package:line_break/line_break_data.dart';

class HashIndex {
  int index;
  int endCodePoint;
}

class HashTableProperties {

  static const int hashTableSize = 64;

  List<LineBreakProperty> properties;

  List hashTable = new List<HashIndex>(hashTableSize);

  HashTableProperties(this.properties);

  void updateHashTable() {
    int step = (properties.length / hashTableSize).floor();
    int index = 0;
    for (int i = 0; i < hashTableSize; ++i) {
      HashIndex hashIndex = HashIndex();
      hashIndex.index = index;
      index += step;
      hashIndex.endCodePoint = properties[index].startCodePoint - 1;
      hashTable[i] = hashIndex;
    }
  }

  LineBreakClass getClassForValue(int value) {
    int start = 0;
    int end = properties.length - 1;

    while (start <= end) {
      int middle = start + ((end - start) >> 1); //((start + end) / 2.0).round();
      LineBreakProperty middleProperty = properties[middle];
      if (middleProperty.contains(value)) {
        return middleProperty.type;
      } else if (middleProperty.startCodePoint > value) {
        end = middle - 1;
      } else {
        start = middle + 1;
      }
    }
    return LineBreakClass.XX;
  }
}


class DefaultProperties extends HashTableProperties {

  DefaultProperties(): super(defaultProperties) {
    this.updateHashTable();
  }

}

class ChineseProperties extends HashTableProperties {

  ChineseProperties(): super([
          LineBreakProperty(0x2018, 0x2018, LineBreakClass.OP),
          LineBreakProperty(0x2019, 0x2019, LineBreakClass.CL),
          LineBreakProperty(0x201C, 0x201C, LineBreakClass.OP),
          LineBreakProperty(0x201D, 0x201D, LineBreakClass.CL),
          ]);

}