library line_break;
import 'dart:math';
import 'dart:core';
import 'package:line_break/properties/line_break_property.dart';
import 'package:line_break/properties/line_break_properties.dart';

enum LineBreakAction {
  direct,
  indirect,
  combiningIndirect,
  prohibited,
  combiningProhibited,
}

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

class LineBreak {

  final List characterClasses = [ 	// treat CB as BB for demo purposes
//  0	1	2	3	4	5	6	7	8	9	a	b	c	d	e	f
	LineBreakClass.AL, LineBreakClass.ZW, LineBreakClass.GL, LineBreakClass.GL, LineBreakClass.BA, LineBreakClass.GL,	LineBreakClass.AL, LineBreakClass.B2, LineBreakClass.IN, LineBreakClass.BA, LineBreakClass.LF, LineBreakClass.CB, LineBreakClass.AL, LineBreakClass.CR, LineBreakClass.NL, LineBreakClass.AL, // 00-0f
	LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL, // 10-1f

//  ' '  !   "       $   %   &   '   (   )   *   +   , LineBreakClass.  -   .    /  
	LineBreakClass.SP, LineBreakClass.EX, LineBreakClass.QU, LineBreakClass.IN, LineBreakClass.PR, LineBreakClass.PO, LineBreakClass.BB, LineBreakClass.QU, LineBreakClass.OP, LineBreakClass.CP, LineBreakClass.BA, LineBreakClass.PR, LineBreakClass.IN, LineBreakClass.HY, LineBreakClass.IN, LineBreakClass.SY, // 20-2f
//   0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
	LineBreakClass.NU, LineBreakClass.NU, LineBreakClass.NU, LineBreakClass.NU, LineBreakClass.NU, LineBreakClass.NU, LineBreakClass.NU, LineBreakClass.NU, LineBreakClass.NU,	LineBreakClass.NU,	LineBreakClass.NS,	LineBreakClass.AL,	LineBreakClass.AL,	LineBreakClass.GL, LineBreakClass.AL,	LineBreakClass.EX,	// 30-3f

//   @, LineBreakClass. A  B   C   D   E   F   G   H   I   J   K   L   M   N   O  
	LineBreakClass.CB, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	// 40-4f
	LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.OP,	LineBreakClass.AL,	LineBreakClass.CP,	LineBreakClass.AL,	LineBreakClass.IS,	// 50-5f ... [ \ ] ^ _ 
	LineBreakClass.CM, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	// 60-6f
	LineBreakClass.AL, LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.AL, LineBreakClass.AL,	LineBreakClass.OP,	LineBreakClass.AL,	LineBreakClass.CL,	LineBreakClass.AL,	LineBreakClass.SA,	// 70-7f ... { | } ~ DEL
//   p  q   r   s   t    u   v   w  x   y   z 
  ];
  
 final List chVisibleFromSpecial = [
    /* ZW  1 chZWSP */ 0x2020, // show as dagger
    /* GL  2 chZWNBSP */ 0x2021, // show as double dagger
    /* GL  3 chNBHY */ 0x00AC, // show as not sign
    /* BA  4 chSHY */ 0x00B7, // show as dot
    /* GL  5 chNBSP */ 0x2017, // show as low line
    /* -- 6 chDummy1 */ 0x203E, // show as double low line
    /* B2 7 chEM */ 0x2014, // show as em dash
    /* IN 8 chELLIPSIS */ 0x2026, // show as ellipsis
    /* CM 9 chTB */ 0x2310, // show as not sign
    /* LF 10 chLFx */ 0x2580, // show as high square
    /* CB 11 chOBJ */ 0x2302, // show as house (delete)
    /* -- 12 chdummy2 */ 0x2222,
    /* CR 13 chCRx */ 0x2584, // show as low square
    /* NL 14 chNLx */ 0x258C, // show as left half block
  ];


  final List pairTable = List<List<LineBreakAction>>(33);
  final DefaultProperties defaultProperties = DefaultProperties();
  final ChineseProperties chineseProperties = ChineseProperties();

  static LineBreak _instance;
  factory LineBreak() => _getInstance();
  static LineBreak get shared => _getInstance();
  static LineBreak _getInstance() {
    if (_instance == null) {
      _instance = LineBreak._internal();
    }
    return _instance;
  }
  LineBreak._internal() {
    _initPairTable();
  }

  HashTableProperties getProperties([String lang]) {
    switch (lang) {
      case "zh": {
        return chineseProperties;
      }
      default: {
        return defaultProperties;
      }
    }
  }

  LineBreakClass getClassForValue(int value, String lang) {
    LineBreakClass lineBreakClass = getProperties(lang).getClassForValue(value);
    if (lineBreakClass == LineBreakClass.XX) {
      lineBreakClass = defaultProperties.getClassForValue(value);
    }

    if(value > 0x2E80) {
			lineBreakClass = isIdeographic(value) ? LineBreakClass.ID : LineBreakClass.NS;
			//对于小括号 中括号 大括号进行特殊处理
			if(value == 0xFF08 || value == 0xFF3B || value == 0xFF5B) { //小 中 大括号
				return LineBreakClass.OP;
			} else if(value == 0xFF09 || value == 0xFF3D || value == 0xFF5D) {
				return LineBreakClass.CP;
      }
			return lineBreakClass;
		}
    if(value == 8216 || value == 8220) {
			return LineBreakClass.OP;
		}
    
    if(value == 8217 || value == 8221) {
			return LineBreakClass.CP;
		}

    lineBreakClass = resolveLineBreakClass(value);
    if (lineBreakClass == LineBreakClass.XX || lineBreakClass == LineBreakClass.AI)
			lineBreakClass = LineBreakClass.AL;

		// map contingent break to B2 by default
		// this saves a row/col for CB in the table
		// but only approximates rule 20
		if (lineBreakClass == LineBreakClass.CB) {
      lineBreakClass = LineBreakClass.B2;
    }
    return lineBreakClass;
  }



LineBreakClass resolveLineBreakClass(int value) {
  int index = value;
  for (int i = 0; i < chVisibleFromSpecial.length; i++) {
		if (value == chVisibleFromSpecial[i]) {
			index = i + 1;
      break;
		}
	}
	if (index >= 0x7f) {
    return LineBreakClass.XX;
  }
	return characterClasses[index];
}



  // LineBreakClass resolveLineBreakClass(LineBreakClass lineBreakClass, [String lang]) {
  //   LineBreakClass result = LineBreakClass.Undefined;
  //   switch (lineBreakClass) {
  //     case LineBreakClass.AI:
  //       result = LineBreakClass.AL;
  //       if (lang == "zh" || lang == "ko" || lang == "ja") {
  //         result = LineBreakClass.ID;
  //       }
  //       break;
  //     case LineBreakClass.SA:
  //     case LineBreakClass.SG:
  //     case LineBreakClass.XX:
  //       result = LineBreakClass.AL;
  //       break;
  //     case LineBreakClass.CJ:
  //       if (lang.endsWith('-strict')){
  //         result = LineBreakClass.NS;
  //       } else {
  //         result = LineBreakClass.ID;
  //       }
  //       break;
  //     default:
  //       result = lineBreakClass;
  //       break;
  //   }
  //   return result;
  // }
  
  List<LineBreakResult> findLineBreaksWithText(String text, [String lang]) {
    return findLineBreaks(text.codeUnits, lang);
  }

  List<LineBreakResult> findLineBreaks(List<int> codeUnits, [String lang]) {
    LineBreakClass firstClass = getClassForValue(codeUnits[0], lang);
    bool fLb8aZwj = firstClass == LineBreakClass.ZWJ; /**< Flag for ZWJ (LB8a) */
    bool fLb10LeadSpace = firstClass == LineBreakClass.SP; /**< Flag for leading space (LB10) */
    bool fLb21aHebrew = false;              /**< Flag for Hebrew letters (LB21a) */
    int cLb30aRI = 0;                   /**< Count of RI characters (LB30a) */

    LineBreakClass currentClass = firstClass; //resolveLineBreakClass(firstClass, lang);
    LineBreakClass prevClass = LineBreakClass.Undefined;
    LineBreakClass nextClass = LineBreakClass.Undefined;
    int length = codeUnits.length;

    List<LineBreakResult> results = List.filled(length, LineBreakResult.none, growable: true);

    for (int i = 1; i < length; i++) {

      switch (currentClass) {
        case LineBreakClass.NL:
        case LineBreakClass.LF:
          currentClass = LineBreakClass.BK;
          break;
        case LineBreakClass.SP:
          currentClass = LineBreakClass.WJ;
          break;
        default: break;
      }

      prevClass = nextClass;
      nextClass = getClassForValue(codeUnits[i], lang);

      if (currentClass == LineBreakClass.BK ||
          (currentClass == LineBreakClass.CR && nextClass != LineBreakClass.LF)) {
        results[i] = LineBreakResult.must;
        currentClass = nextClass;
        continue;
      }

      LineBreakResult result = LineBreakResult.prohibited;
      bool isContinue = false;

      switch(nextClass) {
        case LineBreakClass.SP:  // Rule LB7
          result = LineBreakResult.prohibited;
          isContinue = true;
          break;
        case LineBreakClass.BK: // Rule LB6
        case LineBreakClass.NL:
        case LineBreakClass.LF:
          result = LineBreakResult.prohibited;
          currentClass = LineBreakClass.BK;
          isContinue = true;
          break;
        case LineBreakClass.CR: // Rule LB6
          result = LineBreakResult.prohibited;
          currentClass = LineBreakClass.CR;
          isContinue = true;
          break;
        default: break;
      }

      if (isContinue == false) {
        // nextClass = resolveLineBreakClass(nextClass, lang);
        LineBreakAction action = pairTable[currentClass.index - 1][nextClass.index - 1];

        switch (action) {
          case LineBreakAction.direct:
            result = LineBreakResult.allowed;
            break;
          case LineBreakAction.indirect:
          case LineBreakAction.combiningIndirect:
            result = (prevClass == LineBreakClass.SP) ? LineBreakResult.allowed : LineBreakResult.prohibited;
            break;
          case LineBreakAction.combiningProhibited:
            if (prevClass == LineBreakClass.SP) {
              result = LineBreakResult.prohibited;
            }
            break;
          case LineBreakAction.prohibited:
            result = LineBreakResult.prohibited;
            break;
        }
      }

      if (fLb8aZwj) {
        result = LineBreakResult.prohibited;
      }

      if (fLb21aHebrew &&
          (currentClass == LineBreakClass.HY || currentClass == LineBreakClass.BA)) {
        result = LineBreakResult.prohibited;
        fLb21aHebrew = false;
      } else {
        fLb21aHebrew = currentClass == LineBreakClass.HL;
      }

      if (currentClass == LineBreakClass.RI) {
        cLb30aRI++;
        if (cLb30aRI == 2 && nextClass == LineBreakClass.RI) {
          result = LineBreakResult.allowed;
          cLb30aRI = 0;
        }
      } else {
        cLb30aRI = 0;
      }

      currentClass = nextClass;

      fLb8aZwj = nextClass == LineBreakClass.ZWJ;
      if (fLb10LeadSpace == true) {
        if (nextClass == LineBreakClass.CM || nextClass == LineBreakClass.ZWJ) {
          result = LineBreakResult.allowed;
        }
        fLb10LeadSpace = false;
      }

      results[i - 1] = result;
    }

    results[length - 1] = LineBreakResult.must;
    return results;
  }

  void _initPairTable() {

    LineBreakAction direct = LineBreakAction.direct;
    LineBreakAction indirect = LineBreakAction.indirect;
    LineBreakAction combiningIndirect = LineBreakAction.combiningIndirect;
    LineBreakAction prohibited = LineBreakAction.prohibited;
    LineBreakAction combiningProhibited = LineBreakAction.combiningProhibited;

    int OP = LineBreakClass.OP.index - 1;
    int CL = LineBreakClass.CL.index - 1;
    int CP = LineBreakClass.CP.index - 1;
    int QU = LineBreakClass.QU.index - 1;
    int GL = LineBreakClass.GL.index - 1;
    int NS = LineBreakClass.NS.index - 1;
    int EX = LineBreakClass.EX.index - 1;
    int SY = LineBreakClass.SY.index - 1;
    int IS = LineBreakClass.IS.index - 1;
    int PR = LineBreakClass.PR.index - 1;
    int PO = LineBreakClass.PO.index - 1;
    int NU = LineBreakClass.NU.index - 1;
    int AL = LineBreakClass.AL.index - 1;
    int HL = LineBreakClass.HL.index - 1;
    int ID = LineBreakClass.ID.index - 1;
    int IN = LineBreakClass.IN.index - 1;
    int HY = LineBreakClass.HY.index - 1;
    int BA = LineBreakClass.BA.index - 1;
    int BB = LineBreakClass.BB.index - 1;
    int B2 = LineBreakClass.B2.index - 1;
    int ZW = LineBreakClass.ZW.index - 1;
    int CM = LineBreakClass.CM.index - 1;
    int WJ = LineBreakClass.WJ.index - 1;
    int H2 = LineBreakClass.H2.index - 1;
    int H3 = LineBreakClass.H3.index - 1;
    int JL = LineBreakClass.JL.index - 1;
    int JV = LineBreakClass.JV.index - 1;
    int JT = LineBreakClass.JT.index - 1;
    int RI = LineBreakClass.RI.index - 1;
    int EB = LineBreakClass.EB.index - 1;
    int EM = LineBreakClass.EM.index - 1;
    int ZWJ = LineBreakClass.ZWJ.index - 1;
    int CB = LineBreakClass.CB.index - 1;

    pairTable[OP] = [   /* OP */
      prohibited, prohibited, prohibited, prohibited, prohibited, prohibited, prohibited,
      prohibited, prohibited, prohibited, prohibited, prohibited, prohibited, prohibited,
      prohibited, prohibited, prohibited, prohibited, prohibited, prohibited, prohibited,
      combiningProhibited, prohibited, prohibited, prohibited, prohibited, prohibited, prohibited,
      prohibited, prohibited, prohibited, prohibited, prohibited];

    pairTable[CL] = [   /* CL */
      direct, prohibited, prohibited, indirect, indirect, prohibited, prohibited,
      prohibited, prohibited, indirect, indirect, direct, direct, direct,
      direct, direct, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[CP] = [   /* CP */
      direct, prohibited, prohibited, indirect, indirect, prohibited, prohibited,
      prohibited, prohibited, indirect, indirect, indirect, indirect, indirect,
      direct, direct, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[QU] = [   /* QU */
      prohibited, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, indirect, indirect, indirect, indirect, indirect,
      indirect, indirect, indirect, indirect, indirect, indirect, prohibited,
      combiningIndirect, prohibited, indirect, indirect, indirect, indirect, indirect,
      indirect, indirect, indirect, indirect, indirect];

    pairTable[GL] = [   /* GL */
      indirect, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, indirect, indirect, indirect, indirect, indirect,
      indirect, indirect, indirect, indirect, indirect, indirect, prohibited,
      combiningIndirect, prohibited, indirect, indirect, indirect, indirect, indirect,
      indirect, indirect, indirect, indirect, indirect];

    pairTable[NS] = [   /* NS */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, direct, direct, direct, direct,
      direct, direct, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[EX] = [   /* EX */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, direct, direct, direct, direct,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[SY] = [   /* SY */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, direct, indirect, direct, indirect,
      direct, direct, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[IS] = [   /* IS */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, direct, indirect, indirect, indirect,
      direct, direct, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[PR] = [   /* PR */
      indirect, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, direct, indirect, indirect, indirect,
      indirect, direct, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, indirect, indirect, indirect, indirect, indirect,
      direct, indirect, indirect, indirect, direct];

    pairTable[PO] = [   /* PO */
      indirect, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, direct, indirect, indirect, indirect,
      direct, direct, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[NU] = [   /* NU */
      indirect, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, indirect, indirect, indirect, indirect, indirect,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[AL] = [   /* AL */
      indirect, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, indirect, indirect, indirect, indirect, indirect,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[HL] = [   /* HL */
      indirect, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, indirect, indirect, indirect, indirect, indirect,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[ID] = [   /* ID */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, indirect, direct, direct, direct,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[IN] = [   /* IN */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, direct, direct, direct, direct,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[HY] = [   /* HY */
      direct, prohibited, prohibited, indirect, direct, indirect, prohibited,
      prohibited, prohibited, direct, direct, indirect, direct, direct,
      direct, direct, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[BA] = [   /* BA */
      direct, prohibited, prohibited, indirect, direct, indirect, prohibited,
      prohibited, prohibited, direct, direct, direct, direct, direct,
      direct, direct, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[BB] = [   /* BB */
      indirect, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, indirect, indirect, indirect, indirect, indirect,
      indirect, indirect, indirect, indirect, indirect, indirect, prohibited,
      combiningIndirect, prohibited, indirect, indirect, indirect, indirect, indirect,
      indirect, indirect, indirect, indirect, direct];

    pairTable[B2] = [   /* B2 */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, direct, direct, direct, direct,
      direct, direct, indirect, indirect, direct, prohibited, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[ZW] = [   /* ZW */
      direct, direct, direct, direct, direct, direct, direct,
      direct, direct, direct, direct, direct, direct, direct,
      direct, direct, direct, direct, direct, direct, prohibited,
      direct, direct, direct, direct, direct, direct, direct,
      direct, direct, direct, direct, direct];

    pairTable[CM] = [   /* CM */
      indirect, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, indirect, indirect, indirect, indirect, indirect,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[WJ] = [   /* WJ */
      indirect, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, indirect, indirect, indirect, indirect, indirect,
      indirect, indirect, indirect, indirect, indirect, indirect, prohibited,
      combiningIndirect, prohibited, indirect, indirect, indirect, indirect, indirect,
      indirect, indirect, indirect, indirect, indirect];

    pairTable[H2] = [   /* H2 */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, indirect, direct, direct, direct,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, indirect, indirect,
      direct, direct, direct, indirect, direct];

    pairTable[H3] = [   /* H3 */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, indirect, direct, direct, direct,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, indirect,
      direct, direct, direct, indirect, direct];

    pairTable[JL] = [   /* JL */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, indirect, direct, direct, direct,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, indirect, indirect, indirect, indirect, direct,
      direct, direct, direct, indirect, direct];

    pairTable[JV] = [   /* JV */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, indirect, direct, direct, direct,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, indirect, indirect,
      direct, direct, direct, indirect, direct];

    pairTable[JT] = [   /* JT */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, indirect, direct, direct, direct,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, indirect,
      direct, direct, direct, indirect, direct];

    pairTable[RI] = [   /* RI */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, direct, direct, direct, direct,
      direct, direct, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      indirect, direct, direct, indirect, direct];

    pairTable[EB] = [   /* EB */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, indirect, direct, direct, direct,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, indirect, indirect, direct];

    pairTable[EM] = [   /* EM */
      direct, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, direct, indirect, direct, direct, direct,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[ZWJ] = [   /* ZWJ */
      indirect, prohibited, prohibited, indirect, indirect, indirect, prohibited,
      prohibited, prohibited, indirect, indirect, indirect, indirect, indirect,
      direct, indirect, indirect, indirect, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];

    pairTable[CB] = [   /* CB */
      direct, prohibited, prohibited, indirect, indirect, direct, prohibited,
      prohibited, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, direct, direct, direct, prohibited,
      combiningIndirect, prohibited, direct, direct, direct, direct, direct,
      direct, direct, direct, indirect, direct];
  }


  ///https://github.com/dm04806/LineBreak/blob/master/LineBreakSample/LineBreakSample/LineBreak.cpp#L343
  bool isIdeographic(int c) {
    if (c >= 0x2E80 && c <= 0x2FFF) {
      return true; // CJK, KANGXI RADICALS, DESCRIPTION SYMBOLS
    }
    if (c == 0x3000) {
      return true; // IDEOGRAPHIC SPACE
    }

    if (c >= 0x3000 && c <= 0x303f) //CJK标点符号
    {
      return false;
    }

    if (c >= 0x3040 && c <= 0x309F) //日文平假名
    {
      switch (c) {
        case 0x3041: //  # HIRAGANA LETTER SMALL A
        case 0x3043: //  # HIRAGANA LETTER SMALL I
        case 0x3045: //  # HIRAGANA LETTER SMALL U
        case 0x3047: //  # HIRAGANA LETTER SMALL E
        case 0x3049: //  # HIRAGANA LETTER SMALL O
        case 0x3063: //  # HIRAGANA LETTER SMALL TU
        case 0x3083: //  # HIRAGANA LETTER SMALL YA
        case 0x3085: //  # HIRAGANA LETTER SMALL YU
        case 0x3087: //  # HIRAGANA LETTER SMALL YO
        case 0x308E: //  # HIRAGANA LETTER SMALL WA
        case 0x3095: //  # HIRAGANA LETTER SMALL KA
        case 0x3096: //  # HIRAGANA LETTER SMALL KE
        case 0x309B: //  # KATAKANA-HIRAGANA VOICED SOUND MARK
        case 0x309C: //  # KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
        case 0x309D: //  # HIRAGANA ITERATION MARK
        case 0x309E: //  # HIRAGANA VOICED ITERATION MARK
          return false;
          break;
        default:
          return true;
      }
    }

    if (c >= 0x30A0 && c <= 0x30FF) //日文片假名
    {
      switch (c) {
        case 0x30A0: //  # KATAKANA-HIRAGANA DOUBLE HYPHEN
        case 0x30A1: //  # KATAKANA LETTER SMALL A
        case 0x30A3: //  # KATAKANA LETTER SMALL I
        case 0x30A5: //  # KATAKANA LETTER SMALL U
        case 0x30A7: //  # KATAKANA LETTER SMALL E
        case 0x30A9: //  # KATAKANA LETTER SMALL O
        case 0x30C3: //  # KATAKANA LETTER SMALL TU
        case 0x30E3: //  # KATAKANA LETTER SMALL YA
        case 0x30E5: //  # KATAKANA LETTER SMALL YU
        case 0x30E7: //  # KATAKANA LETTER SMALL YO
        case 0x30EE: //  # KATAKANA LETTER SMALL WA
        case 0x30F5: //  # KATAKANA LETTER SMALL KA
        case 0x30F6: //  # KATAKANA LETTER SMALL KE
        case 0x30FB: //  # KATAKANA MIDDLE DOT
        case 0x30FC: //  # KATAKANA-HIRAGANA PROLONGED SOUND MARK
        case 0x30FD: //  # KATAKANA ITERATION MARK
        case 0x30FE: //  # KATAKANA VOICED ITERATION MARK
          return false;
          break;
        default:
          return true;
      }
    }

    if (c >= 0x3400 && c <= 0x4DB5) {
      return true; // CJK UNIFIED IDEOGRAPHS EXTENSION A
    }
    if (c >= 0x4E00 && c <= 0x9FBB) {
      return true; // CJK UNIFIED IDEOGRAPHS
    }
    if (c >= 0xF900 && c <= 0xFAD9) {
      return true; // CJK COMPATIBILITY IDEOGRAPHS
    }
    if (c >= 0xA000 && c <= 0xA48F) {
      return true; // YI SYLLABLES
    }
    if (c >= 0xA490 && c <= 0xA4CF) {
      return true; // YI RADICALS
    }
    if (c >= 0xFE62 && c <= 0xFE66) {
      return true; // SMALL PLUS SIGN to SMALL EQUALS SIGN
    }
    if (c >= 0xFF10 && c <= 0xFF19) {
      return true; // WIDE DIGITS
    }

    if (c >= 0xFF01 && c <= 0xFF0F) {
      return false;
    }

    if (c >= 0xFF1A && c <= 0xFF20) {
      return false;
    }

    if ((c >= 0xFF21 && c <= 0xFF3A) || (c >= 0xFF41 && c <= 0xFF5A)) {
      return true; //WIDTH　Letter
    }

    return false;
  }
}


void main() {
  LineBreak lineBreak = LineBreak();
  List<LineBreakResult> result = lineBreak.findLineBreaksWithText(r"赵国是一个小国，如这南赡大地的其他小", "zh");

  print(result);
  print(result[15]);
}