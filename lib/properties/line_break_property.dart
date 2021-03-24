enum LineBreakClass {
  Undefined,  // Undefined

  // The following break classes are treated in the pair table.
  OP,         // Opening punctuation
  CL,         // Closing punctuation
  CP,         // Closing parenthesis
  QU,         // Ambiguous quotation
  GL,         // Glue
  NS,         // Non-starters
  EX,         // Exclamation/Interrogation
  SY,         // Symbols allowing break after
  IS,         // Infix separator
  PR,         // Prefix
  PO,         // Postfix
  NU,         // Numeric
  AL,         // Alphabetic
  HL,         // Hebrew letter
  ID,         // Ideographic
  IN,         // Inseparable characters
  HY,         // Hyphen
  BA,         // Break after
  BB,         // Break before
  B2,         // Break on either side (but not pair)
  ZW,         // Zero-width space
  CM,         // Combining marks
  WJ,         // Word joiner
  H2,         // Hangul LV
  H3,         // Hangul LVT
  JL,         // Hangul L Jamo
  JV,         // Hangul V Jamo
  JT,         // Hangul T Jamo
  RI,         // Regional indicator
  EB,         // Emoji base
  EM,         // Emoji modifier
  ZWJ,        // Zero width joiner

  // The following break class is treated in the pair table, but it is not part of Table 2 of UAX #14-37.
  CB,         // Contingent break

  // The following break classes are not treated in the pair table
  AI,         // Ambiguous (alphabetic or ideograph)
  BK,         // Break (mandatory)
  CJ,         // Conditional Japanese starter
  CR,         // Carriage return
  LF,         // Line feed
  NL,         // Next line
  SA,         // South-East Asian
  SG,         // Surrogates
  SP,         // Space
  XX          // Unknown
}

class LineBreakProperty {
  final int startCodePoint;
  final int endCodePoint;
  final LineBreakClass type;

  LineBreakProperty(this.startCodePoint, this.endCodePoint, this.type);

  bool contains(int value) {
    return startCodePoint <= value && value <= endCodePoint;
  }
}