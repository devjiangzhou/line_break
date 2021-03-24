import 'dart:io';
import 'dart:convert';
import 'dart:async';

void handleData(String data, EventSink sink) {

  RegExp regExp = new RegExp(r"^[0-9A-F]+(\.\.[0-9A-F]+)?;[A-Z][A-Z0-9]", caseSensitive: false, multiLine: true);
  RegExp splitExp = new RegExp(r";|\.\.");
  Iterable<Match> matches = regExp.allMatches(data);
  for (Match match in matches) {
    String rawValue = data.substring(match.start, match.end);
    List<String> list = rawValue.split(splitExp);
    String str = "";
    if (list.length == 3) {
       str = "LineBreakProperty(0x" + list[0] + ", 0x" + list[1] + ", LineBreakClass." + list[2] + "),";
    } else {
      str = "LineBreakProperty(0x" + list[0] + ", 0x" + list[0] + ", LineBreakClass." + list[1] + "),";
    }
    sink.add(str);
  }
}

void main() {
  StreamTransformer<String, dynamic> transformer = new StreamTransformer.fromHandlers(handleData: handleData);
  HttpClient()
      .getUrl(Uri.parse("https://www.unicode.org/Public/UCD/latest/ucd/LineBreak.txt"))
      .then((request) => request.close())
      .then((response) => response.transform(Utf8Decoder()).transform(transformer).listen(print));
}