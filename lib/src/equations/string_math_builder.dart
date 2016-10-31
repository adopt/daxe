/*
  This file is part of Daxe.

  Daxe is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Daxe is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Daxe.  If not, see <http://www.gnu.org/licenses/>.
*/

part of equations;

/**
 * Parser for equations with Jaxe's syntax.
 * The parsing happens in two steps :
 * - parsing of the string, with the creation of in-memory structures representing the mathematical meaning of the equation
 * - transformation into presentational MathML
 */
class StringMathBuilder {

  MathRootElement _rootElement;

  /// operators replaced first, before syntax analysis
  static final List<List<String>> special = [
     ["<==", "\u21D0"], ["==>", "\u21D2"], ["<=>", "\u21D4"],
     ["!=", "\u2260"], ["~=", "\u2248"], ["~", "\u223C"],
     ["<=", "\u2264"], [">=", "\u2265"], ["<<", "\u226A"], [">>", "\u226B"],
     //  "->" kepts for backward-compatibility
     ["-->", "\u2192"], ["<->", "\u2194"], ["->", "\u2192"], ["<--", "\u2190"],
     ["equiv", "\u2261"],
     ["forall", "\u2200"], ["quelquesoit", "\u2200"],
     ["exists", "\u2203"], ["ilexiste", "\u2203"],
     ["part", "\u2202"], ["drond", "\u2202"],
     ["nabla", "\u2207"],
     ["prop", "\u221D"],
     ["times", "×"], ["cross", "×"], ["croix", "×"],
     ["wedge", "\u2227"], ["pvec", "\u2227"],
     ["plusmn", "±"], ["plusoumoins", "±"], ["plusminus", "±"],
     ["cap", "\u2229"], ["cup", "\u222A"],
     ["...", "\u2026"]
  ];

  /// operators
  static final String sops =
      "_^#*/\u2207±\u2213\u2227-+\u2200\u2203\u2202×=\u2260\u2248\u223C\u2261<>\u2264\u2265\u226A\u226B\u221D" +
      "|\u2229\u222A\u2190\u2192\u2194\u21D0\u21D2\u21D4";

  /// symbols that can be displayed in italics if they are identifiers
  static final List<List<String>> id_symbols = [
     // lowercase greek
     ["alpha", "\u03B1"], ["beta", "\u03B2"], ["gamma", "\u03B3"],
     ["delta", "\u03B4"], ["epsilon", "\u03B5"], ["zeta", "\u03B6"],
     ["eta", "\u03B7"], ["theta", "\u03B8"], ["iota", "\u03B9"],
     ["kappa", "\u03BA"], ["lambda", "\u03BB"], ["mu", "\u03BC"],
     ["nu", "\u03BD"], ["xi", "\u03BE"], ["omicron", "\u03BF"],
     ["rho", "\u03C1"], ["sigma", "\u03C3"],
     ["tau", "\u03C4"], ["upsilon", "\u03C5"], ["phi", "\u03C6"],
     ["chi", "\u03C7"], ["psi", "\u03C8"], ["omega", "\u03C9"],
     // uppercase greek
     ["Alpha", "\u0391"], ["Beta", "\u0392"], ["Gamma", "\u0393"],
     ["Delta", "\u0394"], ["Epsilon", "\u0395"], ["Zeta", "\u0396"],
     ["Eta", "\u0397"], ["Theta", "\u0398"], ["Iota", "\u0399"],
     ["Kappa", "\u039A"], ["Lambda", "\u039B"], ["Mu", "\u039C"],
     ["Nu", "\u039D"], ["Xi", "\u039E"], ["Omicron", "\u039F"],
     ["Pi", "\u03A0"], ["Rho", "\u03A1"], ["Sigma", "\u03A3"],
     ["Tau", "\u03A4"], ["Upsilon", "\u03A5"], ["Phi", "\u03A6"],
     ["Chi", "\u03A7"], ["Psi", "\u03A8"], ["Omega", "\u03A9"],
     // other greek
     ["thetasym", "\u03D1"], ["upsih", "\u03D2"], ["piv", "\u03D6"],
     ["phiv", "\u03D5"], ["phi1", "\u03D5"]
  ];

  /// symbols that should not be put in italics
  static final List<List<String>> roman_symbols = [
     // lowercase greek
     ["pi", "\u03C0"],
     // other characters
     ["infin", "\u221E"], ["infty", "\u221E"], ["infini", "\u221E"],
     ["parallel", "\u2225"], ["parallèle", "\u2225"],
     ["sun", "\u2609"], ["soleil", "\u2609"],
     ["star", "\u2605"], ["étoile", "\u2605"],
     ["mercury", "\u263F"], ["mercure", "\u263F"],
     ["venus", "\u2640"], ["vénus", "\u2640"],
     ["earth", "\u2295"], ["terre", "\u2295"], // 2641 is the official UNICODE code but 2295 is better with STIX...
     ["mars", "\u2642"], ["jupiter", "\u2643"],
     ["saturn", "\u2644"], ["saturne", "\u2644"],
     ["uranus", "\u26E2"], // UNICODE 6.0 draft !
     ["neptun", "\u2646"], ["neptune", "\u2646"],
     ["planck", "\u210F"],
     ["angstrom", "\u212B"], ["angström", "\u212B"],
     ["asterisk", "*"], ["astérisque", "*"], // \uFF0A ?
     ["ell", "\u2113"], ["smalll", "\u2113"], ["petitl", "\u2113"],
     // names in Xscr come from http://www.w3.org/TR/xml-entity-names/
     ["Ascr", "\u{1D49C}"], ["biga", "\u{1D49C}"], ["granda", "\u{1D49C}"], // \uD835\uDC9C
     ["Bscr", "\u212C"], ["bigb", "\u212C"], ["grandb", "\u212C"],
     ["Cscr", "\u{1D49E}"], ["bigc", "\u{1D49E}"], ["grandc", "\u{1D49E}"], // \uD835\uDC9E
     ["Dscr", "\u{1D49F}"], ["bigd", "\u{1D49F}"], ["grandd", "\u{1D49F}"], // \uD835\uDC9F
     ["Escr", "\u2130"], ["bige", "\u2130"], ["grande", "\u2130"],
     ["Fscr", "\u2131"], ["bigf", "\u2131"], ["grandf", "\u2131"],
     ["Gscr", "\u{1D4A2}"], ["bigg", "\u{1D4A2}"], ["grandg", "\u{1D4A2}"], // \uD835\uDCA2
     ["Hscr", "\u210B"], ["bigh", "\u210B"], ["grandh", "\u210B"],
     ["Iscr", "\u2110"], ["bigi", "\u2110"], ["grandi", "\u2110"],
     ["Jscr", "\u{1D4A5}"], ["bigj", "\u{1D4A5}"], ["grandj", "\u{1D4A5}"], // \uD835\uDCA5
     ["Kscr", "\u{1D4A6}"], ["bigk", "\u{1D4A6}"], ["grandk", "\u{1D4A6}"], // \uD835\uDCA6
     ["Lscr", "\u2112"], ["bigl", "\u2112"], ["grandl", "\u2112"],
     ["Mscr", "\u2133"], ["bigm", "\u2133"], ["grandm", "\u2133"],
     ["Nscr", "\u{1D4A9}"], ["bign", "\u{1D4A9}"], ["grandn", "\u{1D4A9}"], // \uD835\uDCA9
     ["Oscr", "\u{1D4AA}"], ["bigo", "\u{1D4AA}"], ["grando", "\u{1D4AA}"], // \uD835\uDCAA
     ["Pscr", "\u{1D4AB}"], ["bigp", "\u{1D4AB}"], ["grandp", "\u{1D4AB}"], // \uD835\uDCAB
     ["Qscr", "\u{1D4AC}"], ["bigq", "\u{1D4AC}"], ["grandq", "\u{1D4AC}"], // \uD835\uDCAC
     ["Rscr", "\u211B"], ["bigr", "\u211B"], ["grandr", "\u211B"],
     ["Sscr", "\u{1D4AE}"], ["bigs", "\u{1D4AE}"], ["grands", "\u{1D4AE}"], // \uD835\uDCAE
     ["Tscr", "\u{1D4AF}"], ["bigt", "\u{1D4AF}"], ["grandt", "\u{1D4AF}"], // \uD835\uDCAF
     ["Uscr", "\u{1D4B0}"], ["bigu", "\u{1D4B0}"], ["grandu", "\u{1D4B0}"], // \uD835\uDCB0
     ["Vscr", "\u{1D4B1}"], ["bigv", "\u{1D4B1}"], ["grandv", "\u{1D4B1}"], // \uD835\uDCB1
     ["Wscr", "\u{1D4B2}"], ["bigw", "\u{1D4B2}"], ["grandw", "\u{1D4B2}"], // \uD835\uDCB2
     ["Xscr", "\u{1D4B3}"], ["bigx", "\u{1D4B3}"], ["grandx", "\u{1D4B3}"], // \uD835\uDCB3
     ["Yscr", "\u{1D4B4}"], ["bigy", "\u{1D4B4}"], ["grandy", "\u{1D4B4}"], // \uD835\uDCB4
     ["Zscr", "\u{1D4B5}"], ["bigz", "\u{1D4B5}"], ["grandz", "\u{1D4B5}"] // \uD835\uDCB5
  ];

  /// functions that can be displayed without parenthesis when there is one simple argument
  static final List<String> fctnopar = ["sin", "cos", "tan", "acos", "asin", "atan"];

  static final RegExp _numbersExpr = new RegExp("^\\s?([0-9]+([\\.,][0-9]+)?|[\\.,][0-9]+)([Ee][+-]?[0-9]+)?\\s?\$");


  StringMathBuilder(final String s) {
    _rootElement = new MathRootElement();
    final String s2 = addParenthesis(replaceSpecial(s));
    if (s != '') {
      final JEQ jeq = parser(s2);
      MathElement me;
      if (jeq == null)
        me = null;
      else
        me = jeq.toMathML();
      _rootElement.addMathElement(me);
    }
  }

  /**
   * Return the root  element of a math tree
   */
  MathRootElement getMathRootElement()
  {
    return _rootElement;
  }

  String replaceSpecial(String s) {
    for (final List<String> spec in special) {
      int ind = s.indexOf(spec[0]);
      while (ind != -1) {
        s = s.substring(0, ind) + spec[1] + s.substring(ind + spec[0].length);
        ind = s.indexOf(spec[0]);
      }
    }
    return s;
  }

  /**
   * Returns true if the character with position [pos] in the string [s] is
   * really an operator (by interpreting expressions like "1e-1/2+e-1/2").
   */
  static bool operatorAt(String s, int pos) {
    String c = s[pos];
    if (sops.indexOf(c) == -1)
      return(false);
    if (c != '+' && c != '-')
      return(true);
    if (pos < 2)
      return(true);
    c = s[pos - 1];
    if (c != 'E' && c != 'e')
      return(true);
    c = s[pos - 2];
    if ("0123456789".indexOf(c) != -1)
      return(false);
    return(true);
  }

  static String addParenthesis(String s) {
    // first add parenthesis to separate function parameters
    // f(a+1;b;c) -> f((a+1);b;c)
    int indop = s.indexOf(';');
    while (indop != -1) {
      // to the left of ';'
      int pp = 0;
      bool withop = false;
      String c;
      for (int i=indop-1; i>=0 && pp>=0; i--) {
        c = s[i];
        if (c == ';' && pp == 0)
          break; // parenthesis are already added
        if (c == '(')
          pp--;
        else if (c == ')')
          pp++;
        else if (operatorAt(s, i))
          withop = true;
        if (pp < 0 && withop) {
          s = s.substring(0,i) + '(' + s.substring(i,indop) + ')' + s.substring(indop);
          indop += 2;
        }
      }
      // to the right of ';'
      pp = 0;
      withop = false;
      for (int i=indop+1; i<s.length && pp>=0; i++) {
        c = s[i];
        if (c == '(')
          pp++;
        else if (c == ')')
          pp--;
        else if (operatorAt(s, i))
          withop = true;
        if ((pp < 0 || pp == 0 && c == ';') && withop)
          s = s.substring(0,indop+1) + '(' + s.substring(indop+1,i) + ')' + s.substring(i);
        if (c == ';' && pp == 0)
          break;
      }
      final int indop2 = s.substring(indop+1).indexOf(';');
      if (indop2 == -1)
        indop = indop2;
      else
        indop += indop2 + 1;
    }

    // other parenthesis
    for (int iops=0; iops<sops.length; iops++) {
      final String cops = sops[iops];
      indop = s.indexOf(cops);
      while (indop != -1 && !operatorAt(s, indop))
        indop = s.indexOf(cops, indop + 1);
      int nindop = indop;
      int im,ip;
      String cm=' ',cp=' ';
      int pp;
      bool addp;
      while (nindop != -1) {
        addp = false;
        im = indop - 1;
        if (im >= 0)
          cm = s[im];
        pp = 0;
        while (im >= 0 && (pp != 0 || cm != '(') &&
            (pp != 0 || !operatorAt(s, im))) {
          if (cm == ')')
            pp++;
          else if (cm == '(')
            pp--;
          im--;
          if (im >= 0)
            cm = s[im];
        }
        if (im < 0 || operatorAt(s, im))
          addp = true;
        ip = indop + 1;
        if (ip >= 0 && ip <= s.length-1)
          cp = s[ip];
        pp = 0;
        while (ip < s.length && (pp != 0 || cp != ')') &&
        (pp != 0 || !operatorAt(s, ip))) {
          if (cp == '(')
            pp++;
          else if (cp == ')')
            pp--;
          ip++;
          if (ip < s.length)
            cp = s[ip];
        }
        if (ip >= s.length || operatorAt(s, ip))
          addp = true;
        if (addp) {
          s = s.substring(0, im+1) + "(" + s.substring(im+1, ip) + ")" +
              s.substring(ip);
          indop++;
        }
        nindop = s.substring(indop+1).indexOf(cops);
        indop = nindop + indop+1;
      }
    }
    return s;
  }

  JEQ parser(String s) {
    if (s == null || s == '')
      return null;

    if (s[0] == '(' && s[s.length-1] == ')') {
      int pp = 0;
      for (int i=1; i<s.length-1; i++) {
        if (s[i] == '(')
          pp++;
        else if (s[i] == ')')
          pp--;
        if (pp == -1)
          break;
      }
      if (pp != -1)
        s = s.substring(1, s.length-1);
    }

    int indop = -1;
    int pp = 0;
    for (int i=0; i<s.length; i++) {
      if (pp == 0 && operatorAt(s, i)) {
        indop = i;
        break;
      } else if (s[i] == '(')
          pp++;
      else if (s[i] == ')')
        pp--;
    }
    if (indop == -1) {
      bool nb;
      try {
        nb = _numbersExpr.hasMatch(s);
      } on FormatException {
        nb = false;
      }
      if (nb)
        return(new JEQNumber(s));
      final int indf = s.indexOf('(');
      if (indf != -1 && s[s.length-1] == ')') {
        // fctname(p1; p2; ...) or (complexfctname)(p1; p2; ...) ?
        // like (sin^2)(alpha) or (theta_f)(1)
        // looking for a second parenthesis at the same level as the first
        int indf2 = -1;
        pp = 0;
        for (int i=0; i<s.length; i++) {
          final String c = s[i];
          if (c == '(' && pp == 0 && i != indf) {
            indf2 = i;
            break;
          } else if (c == '(')
            pp++;
          else if (c == ')')
            pp--;
        }
        JEQ name = null;
        if (indf2 == -1) {
          name = new JEQVariable(s.substring(0,indf));
          s = s.substring(indf+1, s.length-1);
        } else {
          name = parser(s.substring(0, indf2));
          s = s.substring(indf2+1, s.length-1);
        }
        // looking for parameters
        final List<JEQ> vp = new List<JEQ>();
        //indv = s.indexOf(';'); does not work with f(g(a;b);c)
        int indv = -1;
        pp = 0;
        for (int i=0; i<s.length; i++) {
          final String c = s[i];
          if (c == ';' && pp == 0 ) {
            indv = i;
            break;
          } else if (c == '(')
            pp++;
          else if (c == ')')
            pp--;
        }
        if (indv == -1)
          vp.add(parser(s.trim()));
        else
          while (indv != -1) {
            vp.add(parser(s.substring(0,indv).trim()));
            s = s.substring(indv+1);
            indv = -1;
            pp = 0;
            for (int i=0; i<s.length; i++) {
              final String c = s[i];
              if (c == ';' && pp == 0 ) {
                indv = i;
                break;
              } else if (c == '(')
                pp++;
              else if (c == ')')
                pp--;
            }
            if (indv == -1)
              vp.add(parser(s.trim()));
          }
        return(new JEQFunction(name, vp));
      } else
        return(new JEQVariable(s));
    }

    final String op = s[indop];
    final String s1 = s.substring(0,indop).trim();
    JEQ p1;
    if (s1 == '')
      p1 = null;
    else
      p1 = parser(s1);
    final String s2 = s.substring(indop+1).trim();
    JEQ p2;
    if (s2 == '')
      p2 = null;
    else
      p2 = parser(s2);

    return(new JEQOperation(op, p1, p2));
  }

  static MathElement elemOrQuestion(final JEQ jeq) {
    if (jeq != null)
      return jeq.toMathML();
    final MathText mtext = new MathText();
    mtext.addText("?");
    return mtext;
  }


}

abstract class JEQ {
  MathElement toMathML();
  void setUnits();
}

class JEQFunction implements JEQ {
  JEQ name;
  List<JEQ> vp;
  final RegExp namesExpr = new RegExp("^[0-9]+.*\$");
  JEQFunction(final JEQ name, final List<JEQ> arguments) {
    this.name = name;
    if (name is JEQVariable && namesExpr.hasMatch(name.name)) {
      // a function name starting with digits ?!?
      name.name = "?";
    }
    vp = arguments;
    if ((getFctName() == "unité" || getFctName() == "unit") && vp.length > 1 && vp[1] != null)
      vp[1].setUnits();
  }
  void setUnits() {
    for (JEQ param in vp)
      if (param != null)
        param.setUnits();
  }
  String getFctName() {
    if (name is JEQVariable)
      return((name as JEQVariable).name);
    else
      return(null);
  }
  MathElement toMathML() {
    JEQ p1, p2, p3, p4;
    if (vp.length > 0)
      p1 = vp[0];
    else
      p1 = null;
    if (vp.length > 1)
      p2 = vp[1];
    else
      p2 = null;
    if (vp.length > 2)
      p3 = vp[2];
    else
      p3 = null;
    if (vp.length > 3)
      p4 = vp[3];
    else
      p4 = null;
    String fctname = getFctName();
    MathElement me;
    if (fctname == "sqrt" || (fctname == "racine" && (p1 == null || p2 == null))) {
      me = new MathSqrt();
      me.addMathElement(StringMathBuilder.elemOrQuestion(p1));
    } else if (fctname == "racine" || fctname == "root") {
      me = new MathRoot();
      me.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      me.addMathElement(StringMathBuilder.elemOrQuestion(p2));
    } else if (fctname == "exp") {
      me = new MathSup();
      final MathIdentifier mi = new MathIdentifier();
      mi.addText("e");
      me.addMathElement(mi);
      me.addMathElement(StringMathBuilder.elemOrQuestion(p1));
    } else if (fctname == "abs") {
      me = new MathRow();
      MathOperator mo = new MathOperator();
      mo.addText("|");
      me.addMathElement(mo);
      me.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      mo = new MathOperator();
      mo.addText("|");
      me.addMathElement(mo);
    } else if (fctname == "norm" || fctname == "norme") {
      me = new MathRow();
      MathOperator mo = new MathOperator();
      mo.addText("\u2016");
      me.addMathElement(mo);
      me.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      mo = new MathOperator();
      mo.addText("\u2016");
      me.addMathElement(mo);
    } else if (fctname == "fact" || fctname == "factorielle"
        || fctname == "factorial") {
      me = new MathRow();
      MathOperator mo;
      if (!(p1 is JEQVariable || p1 is JEQNumber)) {
        mo = new MathOperator();
        mo.addText("(");
        me.addMathElement(mo);
      }
      me.addMathElement(p1.toMathML());
      if (!(p1 is JEQVariable || p1 is JEQNumber)) {
        mo = new MathOperator();
        mo.addText(")");
        me.addMathElement(mo);
      }
      mo = new MathOperator();
      mo.addText("!");
      me.addMathElement(mo);
    } else if (fctname == "int" || fctname == "intégrale") {
      me = new MathRow();
      MathOperator mo = new MathOperator();
      mo.addText("\u222B");
      mo.setStretchy(true);
      if (p3 != null && p4 != null) {
        final MathUnderOver munderover = new MathUnderOver();
        munderover.addMathElement(mo);
        munderover.addMathElement(StringMathBuilder.elemOrQuestion(p3));
        munderover.addMathElement(StringMathBuilder.elemOrQuestion(p4));
        me.addMathElement(munderover);
      } else if (p3 != null) {
        final MathUnder munder = new MathUnder();
        munder.addMathElement(mo);
        munder.addMathElement(StringMathBuilder.elemOrQuestion(p3));
        me.addMathElement(munder);
      } else if (p4 != null) {
        final MathOver mover = new MathOver();
        mover.addMathElement(mo);
        mover.addMathElement(StringMathBuilder.elemOrQuestion(p4));
        me.addMathElement(mover);
      } else
        me.addMathElement(mo);
      final MathRow mrow = new MathRow();
      mrow.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      // <mo> &InvisibleTimes; </mo>
      if (p2 != null) {
        mo = new MathOperator();
        mo.addText("d"); // &DifferentialD;
        mrow.addMathElement(mo);
        mrow.addMathElement(p2.toMathML());
      }
      me.addMathElement(mrow);
    } else if (fctname == "prod" || fctname == "sum" ||
        fctname == "produit" || fctname == "somme") {
      me = new MathRow();
      final MathUnderOver munderover = new MathUnderOver();
      final MathOperator mo = new MathOperator();
      if (fctname == "prod" || fctname == "produit")
        mo.addText("\u220F");
      else if (fctname == "sum" || fctname == "somme")
        mo.addText("\u2211");
      mo.setStretchy(true);
      munderover.addMathElement(mo);
      munderover.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      munderover.addMathElement(StringMathBuilder.elemOrQuestion(p3));
      me.addMathElement(munderover);
      final MathRow mrow = new MathRow();
      mrow.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      me.addMathElement(mrow);
    } else if (fctname == "over" || fctname == "dessus") {
      final MathOver mover = new MathOver();
      mover.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      mover.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      me = mover;
    } else if (fctname == "subsup") {
      final MathSubSup msubsup = new MathSubSup();
      msubsup.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      msubsup.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      msubsup.addMathElement(StringMathBuilder.elemOrQuestion(p3));
      me = msubsup;
    } else if (fctname == "accent") {
      final MathOver mover = new MathOver();
      mover.setAccent(true);
      mover.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      if (p2 is JEQOperation && p2.op == '\u223C') {
        final MathOperator mo = new MathOperator();
        mo.setStretchy(true);
        mo.addText("\u223C");
        mover.addMathElement(mo);
      } else
        mover.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      me = mover;
    } else if (fctname == "matrix" || fctname == "matrice") {
      me = new MathRow();
      MathOperator mo = new MathOperator();
      mo.addText("(");
      me.addMathElement(mo);
      final MathTable mtable = new MathTable();
      for (final JEQ mel in vp)
        mtable.addMathElement(StringMathBuilder.elemOrQuestion(mel));
      me.addMathElement(mtable);
      mo = new MathOperator();
      mo.addText(")");
      me.addMathElement(mo);
    } else if (fctname == "system" || fctname == "système") {
      me = new MathRow();
      final MathOperator mo = new MathOperator();
      mo.addText("{");
      me.addMathElement(mo);
      final MathTable mtable = new MathTable();
      for (final JEQ mel in vp) {
        final MathRow mrow = new MathRow();
        final MathTableData mtd = new MathTableData();
        mtd.setColumnAlign("left");
        mtd.addMathElement(StringMathBuilder.elemOrQuestion(mel));
        mrow.addMathElement(mtd);
        mtable.addMathElement(mrow);
      }
      me.addMathElement(mtable);
    } else if (fctname == "line" || fctname == "ligne") {
      me = new MathTableRow();
      for (final JEQ mel in vp) {
        final MathTableData mtd = new MathTableData();
        mtd.addMathElement(StringMathBuilder.elemOrQuestion(mel));
        me.addMathElement(mtd);
      }
    } else if (fctname == "slash") {
      me = new MathRow();
      me.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      final MathOperator mo = new MathOperator();
      mo.addText("/"); // could be \u2215
      me.addMathElement(mo);
      me.addMathElement(StringMathBuilder.elemOrQuestion(p2));
    } else if (fctname == "frac" || fctname == "fraction") {
      final MathFrac mfrac = new MathFrac();
      mfrac.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      mfrac.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      me = mfrac;
    } else if (fctname == "pscalaire" || fctname == "scalarp") {
      final MathRow mrow = new MathRow();
      mrow.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      final MathOperator mo = new MathOperator();
      mo.addText(".");
      mrow.addMathElement(mo);
      mrow.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      return mrow;
    } else if (fctname == "dtemps" || fctname == "timed") {
      final MathOver mover = new MathOver();
      mover.setAccent(true);
      mover.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      MathOperator mop = new MathOperator();
      if (p2 is JEQNumber) {
        try {
          final int n = int.parse(p2.value);
          String spts = "";
          for (int i=0; i<n; i++)
            spts = spts + '.';
          mop.addText(spts);
        } on FormatException {
          mop.addText("?");
        }
      } else
        mop.addText("?");
      mover.addMathElement(mop);
      me = mover;
    } else if (fctname == "unité" || fctname == "unit") {
      final MathRow mrow = new MathRow();
      mrow.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      final MathOperator mo = new MathOperator();
      mo.addText(" ");
      mrow.addMathElement(mo);
      mrow.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      return mrow;
    } else if (fctname == "moyenne" || fctname == "mean") {
      me = new MathRow();
      MathOperator mo = new MathOperator();
      mo.addText("\u2329");
      me.addMathElement(mo);
      me.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      mo = new MathOperator();
      mo.addText("\u232A");
      me.addMathElement(mo);
    } else if (fctname == "vecteur" || fctname == "vector") {
      // vectors are displayed in bold whenever possible
      final MathElement mp1 = StringMathBuilder.elemOrQuestion(p1);
      if (mp1 is MathIdentifier) {
        mp1.setMathvariant("bold");
        me = mp1;
      } else if (mp1 is MathSub && mp1.getMathElement(0) is MathIdentifier) {
        (mp1.getMathElement(0) as MathIdentifier).setMathvariant("bold");
        me = mp1;
      } else {
        final MathOver mover = new MathOver();
        mover.setAccent(true);
        mover.addMathElement(StringMathBuilder.elemOrQuestion(p1));
        final MathOperator mo = new MathOperator();
        mo.setStretchy(true);
        mo.addText("\u2192");
        mover.addMathElement(mo);
        me = mover;
      }
    } else {
      me = new MathRow();
      bool par = true;
      if (name is JEQVariable) {
        MathText mt = new MathText();
        for (final List<String> tsymbole in StringMathBuilder.id_symbols)
          if (fctname == tsymbole[0]) {
            fctname = tsymbole[1];
            break;
          }
        for (final List<String> tsymbole in StringMathBuilder.roman_symbols)
          if (fctname == tsymbole[0]) {
            fctname = tsymbole[1];
            break;
          }
        mt.addText(fctname);
        if (p2 == null && p1 is JEQVariable)
          for (final String element in StringMathBuilder.fctnopar)
            if (fctname == element) {
              par = false;
              break;
            }
        me.addMathElement(mt);
      } else
        me.addMathElement(name.toMathML());
      if (par) {
        final MathOperator mo = new MathOperator();
        mo.addText("("); // \u2061 = &ApplyFunction; would be better but not recognized
        me.addMathElement(mo);
      }
      me.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      for (int i=1; i<vp.length; i++) { // WARNING the loop starts at 1
        final MathOperator mo = new MathOperator();
      mo.addText(";");
      me.addMathElement(mo);
      me.addMathElement(StringMathBuilder.elemOrQuestion(vp[i]));
      }
      if (par) {
        final MathOperator mo = new MathOperator();
        mo.addText(")");
        me.addMathElement(mo);
      } else {
        final MathText mtext = new MathText();
        mtext.addText("\u00A0"); // nbsp, mspace would be better
        me.addMathElement(mtext);
      }
    }
    return me;
  }
}

class JEQOperation implements JEQ {
  String op;
  JEQ p1, p2;
  bool units;
  JEQOperation(final String op, final JEQ p1, final JEQ p2) {
    this.op = op;
    this.p1 = p1;
    this.p2 = p2;
    units = false;
    if (op == '#' && p2 != null)
      p2.setUnits();
  }
  void setUnits() {
    units = true;
    if (p1 != null)
      p1.setUnits();
    if (p2 != null)
      p2.setUnits();
  }
  MathElement toMathML() {
    if (op == '/') {
      final MathFrac mfrac = new MathFrac();
      mfrac.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      mfrac.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      return mfrac;
    } else if (op == '^') {
      final MathSup msup = new MathSup();
      bool par;
      if (p1 is JEQFunction) {
        String fctname = (p1 as JEQFunction).getFctName();
        if (fctname == "sqrt" || fctname == "racine")
          par = false;
        else if (fctname == "abs")
          par = false;
        else if (fctname == "matrice")
          par = false;
        else if (fctname == "dtemps" || fctname == "timed")
          par = false;
        else
          par = true;
      } else if (p1 is JEQOperation) {
        String op = (p1 as JEQOperation).op;
        if (op == '_')
          par = false;
        else
          par = true;

      } else
        par = false;
      MathElement me1;
      if (par)
        me1 = addPar(p1.toMathML());
      else
        me1 = StringMathBuilder.elemOrQuestion(p1);
      msup.addMathElement(me1);
      msup.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      return msup;
    } else if (op == '_') {
      final MathSub msub = new MathSub();
      msub.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      msub.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      return msub;
    } else if (op == '#') { // équivalent à la fonction unité
      final MathRow mrow = new MathRow();
      mrow.addMathElement(StringMathBuilder.elemOrQuestion(p1));
      mrow.addMathElement(StringMathBuilder.elemOrQuestion(p2));
      return mrow;
    } else if (op == '*') {
      final MathRow mrow = new MathRow();
      MathElement me1 = StringMathBuilder.elemOrQuestion(p1);
      if (p1 is JEQOperation && "+-".indexOf((p1 as JEQOperation).op) != -1)
        me1 = addPar(me1);
      mrow.addMathElement(me1);

      JEQ firstInP2 = p2;
      if (p2 != null)
        while (firstInP2 is JEQOperation && firstInP2.p1 != null) {
          firstInP2 = (firstInP2 as JEQOperation).p1;
        }
      final bool p2number = firstInP2 is JEQNumber;
      bool scalarp1 = false;
      if (p1 is JEQFunction) {
        final String nomfct = (p1 as JEQFunction).getFctName();
        if (nomfct == "pscalaire" || nomfct == "scalarp")
          scalarp1 = true;
      }
      bool scalarp2 = false;
      if (p2 is JEQFunction) {
        final String nomfct = (p2 as JEQFunction).getFctName();
        if (nomfct == "pscalaire" || nomfct == "scalarp")
          scalarp2 = true;
      }
      if (p2number || (scalarp1 && scalarp2)) {
        final MathOperator mo = new MathOperator();
        mo.addText("×");
        mrow.addMathElement(mo);
      } else {
        if (units) {
          final MathOperator mo = new MathOperator();
          mo.addText(".");
          mrow.addMathElement(mo);
        }
        // else <mo> &InvisibleTimes; </mo>
      }

      MathElement me2 = StringMathBuilder.elemOrQuestion(p2);
      if (p2 is JEQOperation && "+-".indexOf((p2 as JEQOperation).op) != -1)
        me2 = addPar(me2);
      mrow.addMathElement(me2);
      return mrow;
    } else if (op == '-') {
      final MathRow mrow = new MathRow();
      if (p1 != null)
        mrow.addMathElement(p1.toMathML());
      final MathOperator mo = new MathOperator();
      mo.addText("-");
      mrow.addMathElement(mo);
      if (p2 != null) {
        MathElement me2 = p2.toMathML();
        if (p2 is JEQOperation && "+-".indexOf((p2 as JEQOperation).op) != -1)
          me2 = addPar(me2);
        mrow.addMathElement(me2);
      }
      return mrow;
    } else if (op == '+') {
      final MathRow mrow = new MathRow();
      if (p1 != null)
        mrow.addMathElement(p1.toMathML());
      final MathOperator mo = new MathOperator();
      mo.addText("+");
      mrow.addMathElement(mo);
      if (p2 != null) {
        MathElement me2 = p2.toMathML();
        if (me2 is MathRow && me2.getMathElementCount() > 0) {
          MathElement me2b = me2;
          while (me2b is MathRow && me2b.getMathElementCount() > 0)
            me2b = me2b.getMathElement(0);
          if (me2b.getText() == "-")
            me2 = addPar(me2);
        }
        mrow.addMathElement(me2);
      }
      return mrow;
    } else {
      final MathRow mrow = new MathRow();
      if (p1 != null) {
        MathElement me1 = p1.toMathML();
        if (op == '\u2227' && p1 is JEQOperation && "+-".indexOf((p1 as JEQOperation).op) != -1)
          me1 = addPar(me1);
        mrow.addMathElement(me1);
      }
      final MathOperator mo = new MathOperator();
      mo.addText(op);
      if ("=\u2260\u2248\u223C\u2261\u2264\u2265\u226A\u226B\u221D".indexOf(op) != -1) {
        // space around equality operators
        mo.setLspace(0.5);
        mo.setRspace(0.5);
      }
      mrow.addMathElement(mo);
      if (p2 != null) {
        MathElement me2 = p2.toMathML();
        if (op == '\u2227' && p2 is JEQOperation && "+-".indexOf((p2 as JEQOperation).op) != -1)
          me2 = addPar(me2);
        mrow.addMathElement(me2);
      }
      return mrow;
    }
  }
  MathElement addPar(final MathElement me) {
    final MathRow mrow = new MathRow();
    MathOperator mo = new MathOperator();
    mo.addText("(");
    mrow.addMathElement(mo);
    mrow.addMathElement(me);
    mo = new MathOperator();
    mo.addText(")");
    mrow.addMathElement(mo);
    return mrow;
  }
}

class JEQNumber implements JEQ {
  String value;
  JEQNumber(final String value) {
    this.value = value;
  }
  void setUnits() {
  }
  MathElement toMathML() {
    final MathNumber mn = new MathNumber();
    mn.addText(value);
    return mn;
  }
}

class JEQVariable implements JEQ {
  String name;
  bool units;
  final RegExp badExpr = new RegExp("^[0-9]+[a-zA-Z]+\$");
  JEQVariable(final String name) {
    this.name = name.trim();
    units = false;
  }
  void setUnits() {
    units = true;
  }
  MathElement toMathML() {
    if (name == "hat" || name == "chapeau") {
      final MathOperator mo = new MathOperator();
      mo.setStretchy(true);
      mo.addText("^");
      return mo;
    } else if (name == "bar" || name == "barre") {
      final MathOperator mo = new MathOperator();
      mo.setStretchy(true);
      mo.addText("\u00AF");
      return mo;
    } else {
      String s = name;
      bool roman = units;  // units must not be in italics
      for (final List<String> tsymbol in StringMathBuilder.id_symbols)
        if (s == tsymbol[0]) {
          s = tsymbol[1];
          break;
        }
      for (final List<String> tsymbol in StringMathBuilder.roman_symbols)
        if (s == tsymbol[0]) {
          s = tsymbol[1];
          roman = true;
          break;
        }
      if (s.indexOf(',') != -1 || s.indexOf('.') != -1 || s.indexOf('(') != -1 || s.indexOf(')') != -1)
        s = "?"; // ',', '.' and parenthesis are prohibited in variable names
      if (s.indexOf(' ') != -1)
        s = s.replaceAll(" ", "?"); // spaces too
      if (s.indexOf('\u00A0') != -1) // nice try
        s = s.replaceAll("\u00A0", "?");
      if (badExpr.hasMatch(s))
        s = "?"; // missing * operator
      MathElement me;
      if (roman)
        me = new MathText();
      else
        me = new MathIdentifier();
      me.addText(s);
      return me;
    }
  }
}
