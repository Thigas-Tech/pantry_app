/// Removes common Latin diacritics from [input] and lowercases the result.
///
/// Handles characters found in European languages: `à`, `é`, `ñ`, `ü`, `ç`,
/// etc. ASCII characters and unmodified Latin letters pass through unchanged.
/// This is deliberately _not_ a full Unicode NFD decomposition — it covers the
/// 95th‑percentile case for food‑product names at a fraction of the complexity.
///
/// Example:
/// `removeDiacritics('Cafe creme')` returns `'cafe creme'`.
/// `removeDiacritics('Musli')` returns `'musli'`.
String removeDiacritics(String input) {
  if (input.isEmpty) return input;
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    buffer.writeCharCode(_base(input.codeUnitAt(i)));
  }
  return buffer.toString().toLowerCase();
}

int _base(int code) {
  // Latin-1 Supplement (U+00C0–U+00FF) and Latin Extended-A (U+0100–U+017F)
  // Map accented characters to their base ASCII equivalents.
  switch (code) {
    // À-Å → A
    case 0xC0:
    case 0xC1:
    case 0xC2:
    case 0xC3:
    case 0xC4:
    case 0xC5:
      return 0x41;
    // Æ → AE
    case 0xC6:
      return 0x41; // keep as A for search purposes
    // Ç → C
    case 0xC7:
      return 0x43;
    // È-Ë → E
    case 0xC8:
    case 0xC9:
    case 0xCA:
    case 0xCB:
      return 0x45;
    // Ì-Ï → I
    case 0xCC:
    case 0xCD:
    case 0xCE:
    case 0xCF:
      return 0x49;
    // Ð → D
    case 0xD0:
      return 0x44;
    // Ñ → N
    case 0xD1:
      return 0x4E;
    // Ò-Ö → O
    case 0xD2:
    case 0xD3:
    case 0xD4:
    case 0xD5:
    case 0xD6:
      return 0x4F;
    case 0xD7: // multiplication sign
      return code;
    // Ø → O
    case 0xD8:
      return 0x4F;
    // Ù-Ü → U
    case 0xD9:
    case 0xDA:
    case 0xDB:
    case 0xDC:
      return 0x55;
    // Ý → Y
    case 0xDD:
      return 0x59;
    // Þ → P (thorn)
    case 0xDE:
      return 0x50;
    // ß → ss
    case 0xDF:
      return 0x73;
    // à-å → a
    case 0xE0:
    case 0xE1:
    case 0xE2:
    case 0xE3:
    case 0xE4:
    case 0xE5:
      return 0x61;
    // æ → ae
    case 0xE6:
      return 0x61;
    // ç → c
    case 0xE7:
      return 0x63;
    // è-ë → e
    case 0xE8:
    case 0xE9:
    case 0xEA:
    case 0xEB:
      return 0x65;
    // ì-ï → i
    case 0xEC:
    case 0xED:
    case 0xEE:
    case 0xEF:
      return 0x69;
    // ð → d
    case 0xF0:
      return 0x64;
    // ñ → n
    case 0xF1:
      return 0x6E;
    // ò-ö → o
    case 0xF2:
    case 0xF3:
    case 0xF4:
    case 0xF5:
    case 0xF6:
      return 0x6F;
    case 0xF7: // division sign
      return code;
    // ø → o
    case 0xF8:
      return 0x6F;
    // ù-ü → u
    case 0xF9:
    case 0xFA:
    case 0xFB:
    case 0xFC:
      return 0x75;
    // ý-ÿ → y
    case 0xFD:
    case 0xFF:
      return 0x79;
    // thorn → p
    case 0xFE:
      return 0x70;

    // Latin Extended-A: Ā-ă → a, Ą → a, Ć-ć → c, Č → c, Ď → d, Ē-ě → e,
    // Ğ → g, İ → i, Ł → l, Ń → n, Ň → n, Ő → o, Ř → r, Ś → s, Ş → s,
    // Š → s, Ť → t, Ů → u, Ű → u, Ź → z, Ż → z, Ž → z, etc.
    // Upper-case A with diacritics
    case 0x0100:
    case 0x0102:
    case 0x0104:
      return 0x41;
    // Lower-case a with diacritics
    case 0x0101:
    case 0x0103:
    case 0x0105:
      return 0x61;
    // Ć → C, ĉ → c
    case 0x0106:
    case 0x0108:
    case 0x010A:
    case 0x010C:
      return 0x43;
    case 0x0107:
    case 0x0109:
    case 0x010B:
    case 0x010D:
      return 0x63;
    // Ď → D, đ → d
    case 0x010E:
      return 0x44;
    case 0x010F:
    case 0x0111:
      return 0x64;
    // Ē-ě → E
    case 0x0112:
    case 0x0114:
    case 0x0116:
    case 0x0118:
    case 0x011A:
      return 0x45;
    case 0x0113:
    case 0x0115:
    case 0x0117:
    case 0x0119:
    case 0x011B:
      return 0x65;
    // Ğ → G, Ģ → G
    case 0x011E:
    case 0x0120:
    case 0x0122:
      return 0x47;
    case 0x011F:
    case 0x0121:
    case 0x0123:
      return 0x67;
    // Ĥ → H, Ħ → H
    case 0x0124:
    case 0x0126:
      return 0x48;
    case 0x0125:
    case 0x0127:
      return 0x68;
    // İ → I, Ī → I, Ĭ → I, Į → I
    case 0x012E:
      return 0x49;
    case 0x012F:
      return 0x69;
    // ı (dotless i) → i
    case 0x0131:
      return 0x69;
    // Ĵ → J
    case 0x0134:
      return 0x4A;
    case 0x0135:
      return 0x6A;
    // Ķ → K, ĸ → k (kra)
    case 0x0136:
      return 0x4B;
    case 0x0137:
    case 0x0138:
      return 0x6B;
    // Ĺ → L, Ļ → L, Ľ → L, Ł → L
    case 0x0139:
    case 0x013B:
    case 0x013D:
    case 0x0141:
      return 0x4C;
    case 0x013A:
    case 0x013C:
    case 0x013E:
    case 0x0142:
      return 0x6C;
    // Ń → N, Ņ → N, Ň → N, Ŋ → N
    case 0x0143:
    case 0x0145:
    case 0x0147:
    case 0x014A:
      return 0x4E;
    case 0x0144:
    case 0x0146:
    case 0x0148:
    case 0x014B:
      return 0x6E;
    // Ō → O, Ŏ → O, Ő → O
    case 0x014C:
    case 0x014E:
    case 0x0150:
      return 0x4F;
    case 0x014D:
    case 0x014F:
    case 0x0151:
      return 0x6F;
    // Ŕ → R, Ŗ → R, Ř → R
    case 0x0154:
    case 0x0156:
    case 0x0158:
      return 0x52;
    case 0x0155:
    case 0x0157:
    case 0x0159:
      return 0x72;
    // Ś → S, Ŝ → S, Ş → S, Š → S
    case 0x015A:
    case 0x015C:
    case 0x015E:
    case 0x0160:
      return 0x53;
    case 0x015B:
    case 0x015D:
    case 0x015F:
    case 0x0161:
      return 0x73;
    // Ţ → T, Ť → T, Ŧ → T
    case 0x0162:
    case 0x0164:
    case 0x0166:
      return 0x54;
    case 0x0163:
    case 0x0165:
    case 0x0167:
      return 0x74;
    // Ū → U, Ŭ → U, Ů → U, Ű → U, Ų → U
    case 0x016A:
    case 0x016C:
    case 0x016E:
    case 0x0170:
    case 0x0172:
      return 0x55;
    case 0x016B:
    case 0x016D:
    case 0x016F:
    case 0x0171:
    case 0x0173:
      return 0x75;
    // Ŵ → W
    case 0x0174:
      return 0x57;
    case 0x0175:
      return 0x77;
    // Ŷ → Y, Ÿ → Y
    case 0x0176:
    case 0x0178:
      return 0x59;
    case 0x0177:
      return 0x79;
    // Ź → Z, Ż → Z, Ž → Z
    case 0x0179:
    case 0x017B:
    case 0x017D:
      return 0x5A;
    case 0x017A:
    case 0x017C:
    case 0x017E:
      return 0x7A;
    default:
      return code;
  }
}

/// Compares [a] and [b] ignoring case and diacritics.
///
/// Useful for string equality checks in tests.
bool equalsIgnoreCaseAndDiacritics(String a, String b) {
  return removeDiacritics(a) == removeDiacritics(b);
}
