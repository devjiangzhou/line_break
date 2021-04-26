# line_break
支持 Dart 版本 Unicode 12 Line Break 算法，
参考自 
libunibreak [https://github.com/adah1972/libunibreak]
NLineBreak [https://github.com/Rungee/NLineBreak/]

## Getting Started
```
enum LineBreakResult {
  //必须换行
  must,
  //允许换行
  allowed,
  //禁止换行
  prohibited,
  //默认
  none,
}
List<LineBreakResult> findLineBreaks(String text, [String lang])
```
