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
 * This class presents a operator, like "(" or "*"
 */
class MathOperator extends MathElement {

  /** The XML element from this class */
  static final String ELEMENT = "mo";

  /** Attribute name of the stretchy property */
  static final String ATTRIBUTE_STRETCHY = "stretchy";
  
  bool _stretchy = true;
  double _lspace = 0.0; // left space, in em
  double _rspace = 0.0; // right space, in em

  
  MathOperator() : super();
  
  
  /**
   * Enables, or disables if the operator should fit his
   * size to the size of the container
   *
   * @param stretchy True, if the operater should fit this size
   */
  void setStretchy(final bool stretchy) {
    this._stretchy = stretchy;
  }
  
  /**
   * Set left space in em
   */
  void setLspace(final double lspace) {
    this._lspace = lspace;
  }
  
  /**
   * Set right space in em
   */
  void setRspace(final double rspace) {
    this._rspace = rspace;
  }
  
  /**
   * Paints a delimitier
   *
   * @param context The graphics context to use for painting 
   * @param posX The first left position for painting 
   * @param posY The position of the baseline
   * @param upperSymbol The symbol for upper edge
   * @param middleSymbol The symbol for middle part
   * @param lowerSymbol The symbol for lower edge
   */
  void paintDelimiter(final h.CanvasRenderingContext2D context, final double posX, final double posY,
                      final String upperSymbol, final String middleSymbol, final String lowerSymbol)
  {
    context.font = getFont();
    final double height = getExprHeight();
    final double aheight = getExprAscentHeight();
    TextMetrics topMetrics = new TextMetrics(upperSymbol, getFont());
    TextMetrics midMetrics = new TextMetrics(middleSymbol, getFont());
    TextMetrics botMetrics = new TextMetrics(lowerSymbol, getFont());
    
    double topHeight = topMetrics.actualBoundingBoxAscent + topMetrics.actualBoundingBoxDescent;
    double topAscent = topMetrics.actualBoundingBoxAscent;
    double midHeight = midMetrics.actualBoundingBoxAscent + midMetrics.actualBoundingBoxDescent;
    double midAscent = midMetrics.actualBoundingBoxAscent;
    double botHeight = botMetrics.actualBoundingBoxAscent + botMetrics.actualBoundingBoxDescent;
    double botAscent = botMetrics.actualBoundingBoxAscent;
    
    if (height - topHeight - botHeight > 0) {
      final double goal = height - topHeight - botHeight + 2;
      double sy = goal / midHeight;
      context.save();
      context.scale(1, sy);
      context.fillText(middleSymbol, posX, (posY - aheight + topHeight)/sy + midAscent);
      context.restore();
    }
    context.fillText(upperSymbol, posX, posY - aheight + topAscent);
    context.fillText(lowerSymbol, posX, posY + height - aheight - (botHeight - botAscent).round());
  }

  /**
   * Paints a delimitier
   *
   * @param context The graphics context to use for painting 
   * @param posX The first left position for painting 
   * @param posY The position of the baseline 
   * @param upperSymbol The symbol for upper edge
   * @param middleSymbol The symbol for middle part
   * @param connectSymbol The symbol for connecting the middle part with the edges
   * @param lowerSymbol The symbol for lower edge
   */
  void paintCurlyDelimiter(final h.CanvasRenderingContext2D context, final double posX, final double posY,
                           final String upperSymbol, final String middleSymbol,
                           final String connectSymbol, final String lowerSymbol)
  {
    final double height = getExprHeight();

    context.fillStyle = 'black';
    context.font = getFont();
//TODO: keep this in a cache, or optimize TextMetrics
    TextMetrics metrics = new TextMetrics(connectSymbol, getFont());
    final double cheight = metrics.actualBoundingBoxAscent + metrics.actualBoundingBoxDescent;
    
    final int halfcount = ((height / cheight) / 2).floor();

    for (int i = 1; i < halfcount; i++) {
      context.fillText(connectSymbol, posX, posY - cheight * i);
      context.fillText(connectSymbol, posX, posY + cheight * i);
    }
    context.fillText(middleSymbol, posX, posY);
    context.fillText(upperSymbol, posX, posY - cheight * halfcount);
    context.fillText(lowerSymbol, posX, posY + cheight * halfcount);
  }

  /**
   * Paints a horizontal delimitier
   *
   * @param context The graphics context to use for painting 
   * @param posX The first left position for painting 
   * @param posY The position of the baseline 
   * @param upperSymbol The symbol for upper edge
   * @param middleSymbol The symbol for middle part
   * @param connectSymbol The symbol for connecting the middle part with the edges
   * @param lowerSymbol The symbol for lower edge
   */
  void paintCurlyDelimiterHorizontal(final h.CanvasRenderingContext2D context, final double posX, final double posY,
                                     final String upperSymbol,
                                     final String middleSymbol,
                                     final String connectSymbol,
                                     final String lowerSymbol)
  {
    final double height = getParent().getWidth(true);
    final double middle = posY - getMiddleShift();

    context.save();
    context.fillStyle = 'black';
    context.font = getFont();
// THIS HAS NOT BEEN TESTED
    context.translate(posX, posY);
    context.rotate(PI / 2.0);
    context.translate(-posX, -middle);

    final double ascent = getFontMetrics().ascent - 1;
    int countparts = (height / ascent).floor();
    final int halfcount = countparts ~/ 2;

    for (int i = 1; i < halfcount; i++)
    {
      context.fillText(connectSymbol, posX, posY - ascent * i);
      context.fillText(connectSymbol, posX, posY + ascent * i);
    }
    context.fillText(middleSymbol, posX, posY);
    context.fillText(upperSymbol, posX, posY - ascent * halfcount);
    context.fillText(lowerSymbol, posX, posY + ascent * halfcount);

    context.restore();
  }

  @override
  void paint(final h.CanvasRenderingContext2D context, double posX, final double posY) {
    if (_lspace != 0) {
      final double empix = stringWidth('A');
      posX += _lspace * empix;
    }
    if (getText().length == 1
        && "[{(|)}]\u222B".indexOf(getText()[0]) >= 0
        && _stretchy)
    {
      final double ascent = getParent().getAscentHeight(false);
      final double descent = getParent().getDescentHeight(false);
      final double height = ascent + descent - 1;

      if (getText() == "(")
      {
        if (height < getFontMetrics().height)
        {
          context.font = getFont();
          context.fillText(getText(), posX, posY);
        }
        else
          paintDelimiter(context, posX, posY, '\u239B', '\u239C', '\u239D');
      }
      else if (getText() == ")")
      {
        if (height < getFontMetrics().height)
        {
          context.font = getFont();
          context.fillText(getText(), posX, posY);
        }
        else
          paintDelimiter(context, posX, posY, '\u239E', '\u239F', '\u23A0');
      }
      else if (getText() == "[")
      {
        if (height < getFontMetrics().height)
        {
          context.font = getFont();
          context.fillText(getText(), posX, posY);
        }
        else
          paintDelimiter(context, posX, posY, '\u23A1', '\u23A2', '\u23A3');
      }
      else if (getText() == "]")
      {
        if (height < getFontMetrics().height)
        {
          context.font = getFont();
          context.fillText(getText(), posX, posY);
        }
        else
          paintDelimiter(context, posX, posY, '\u23A4', '\u23A5', '\u23A6');

      }
      else if (getText() == "{")
      {
        if (height < getFontMetrics().height)
        {
          context.font = getFont();
          context.fillText(getText(), posX, posY);
        }
        else
          paintCurlyDelimiter(context, posX, posY, '\u23A7', '\u23A8', '\u23AA', '\u23A9');
      }
      else if (getText() == "}")
      {
        if (height < getFontMetrics().height)
        {
          context.font = getFont();
          context.fillText(getText(), posX, posY);
        }
        else
          paintCurlyDelimiter(context, posX, posY, '\u23AB', '\u23AC', '\u23AA', '\u23AD');
      }
      else if (getText() == "|")
      {
        context.beginPath();
        context.moveTo(posX + 2, posY - ascent);
        context.lineTo(posX + 2, posY + descent);
        context.stroke();
      }
      else if (getText() == "\u222B")
      {
        paintDelimiter(context, posX, posY, '\u2320', '\u23AE', '\u2321');
      }
    }
    else if (getText().length == 1
        && "\uFE37\uFE38".indexOf(getText()[0]) >= 0)
    {
      //final int width = getParent().getWidth(true);
      //final int halfwidth = width / 2;
      //final int height = max((int) (width * 0.2), 2);
      //final int halfheight = height / 2;

      if (getText() == "\uFE37")
        paintCurlyDelimiterHorizontal(context, posX, posY, '\u23A7', '\u23A8', '\u23AA', '\u23A9');
      else if (getText() == "\uFE38")
        paintCurlyDelimiterHorizontal(context, posX, posY, '\u23AB', '\u23AC', '\u23AA', '\u23AD');
    }
    else if (getText().length == 1
        && "\u2211\u220F".indexOf(getText()[0]) >= 0
        && _stretchy)
    {
      context.strokeStyle = 'black';
      context.fillStyle = 'black';
      if (getExprHeight() > getFontMetrics().height) {
        final String bigfont = getMathBase().getFont(getFontSize() * 2);
        context.font = bigfont;
      } else
        context.font = getFont();
      if ("\u2211".indexOf(getText()[0]) >= 0)
        context.fillText("\u2211", posX, posY);
      else
        context.fillText("\u220F", posX, posY);
      context.font = getFont();
    }
    else if (getText() == "\u00AF" && _stretchy) // over bar
    {
      final double width = getParent().getWidth(false) - 2;
      context.beginPath();
      context.moveTo(posX, posY);
      context.lineTo(posX + width, posY);
      context.stroke();
    }
    else if (getText() == "^" && _stretchy) // hat
    {
      final double width = getParent().getWidth(false) - 3;
      context.beginPath();
      context.moveTo(posX, posY);
      context.lineTo(posX + width/2, posY - 3);
      context.moveTo(posX + width/2, posY - 3);
      context.lineTo(posX + width, posY);
      context.stroke();
    }
    else if (getText() == "." || getText() == ".." || getText() == "...")
    {
      context.font = getFont();
      context.fillText(getText(), posX + 1, posY);
    }
    else
    {
      context.font = getFont();
      context.fillText(getText(), posX, posY);
    }
  }
  
  MathElement getExpr() {
    if (getText() == "\u222B" || "\u2211\u220F".contains(getText())) {
      MathRow row;
      if (getParent() is MathRow)
        row = getParent() as MathRow;
      else
        row = getParent().getParent() as MathRow;
      // test intégrale/sommation/produit double
      final MathElement contenu = row.getMathElement(1);
      if (!(contenu is MathRow && contenu.getMathElementCount() > 0))
        return(contenu);
      final MathElement interieur1 = contenu.getMathElement(0);
      if (!(interieur1 is MathRow && interieur1.getMathElementCount() > 0))
        return(contenu);
      final MathElement interieur2 = interieur1.getMathElement(0);
      if (!(interieur2 is MathUnderOver || interieur2 is MathUnder ||
          interieur2 is MathOver || interieur2 is MathOperator))
        return(contenu);
      MathElement op;
      if (interieur2 is MathUnderOver || interieur2 is MathUnder || interieur2 is MathOver)
        op = interieur2.getMathElement(0);
      else
        op = interieur2;
      if (!(op.getText() == "\u222B" || "\u2211\u220F".contains(op.getText())))
        return(contenu);
      return(interieur1.getMathElement(1));
    } else
      return(getParent());
  }
  
  double getExprHeight() {
    return(getExpr().getHeight(false));
  }

  double getExprAscentHeight() {
    return(getExpr().getAscentHeight(false));
  }

  double getExprDescentHeight() {
    return(getExpr().getDescentHeight(false));
  }

  @override
  double getWidth(final bool dynamicParts) {
    double totalspace = 0.0;
    if (_lspace != 0 || _rspace != 0) {
      final double empix = stringWidth('A');
      final double lspacepix = _lspace * empix;
      final double rspacepix = _rspace * empix;
      totalspace = lspacepix + rspacepix;
    }
    if (getText().length == 1) {
      final String firstchar = getText()[0];
      if ("|".indexOf(firstchar) >= 0)
        return 5 + totalspace;
      else if ("\uFE37\uFE38".indexOf(firstchar) >= 0)
        return 1 + totalspace;
      else if ("\u222B".indexOf(firstchar) >= 0) {
        TextMetrics tm = new TextMetrics(getText(), getMathBase().getFont(getFontSize()*2));
        return tm.width + totalspace;
      } else if ("\u2211\u220F".indexOf(firstchar) >= 0) {
        if (getExprHeight() > getFontMetrics().height) {
          TextMetrics tm = new TextMetrics(getText(), getMathBase().getFont(getFontSize()*2));
          return tm.width + totalspace;
        } else
          return stringWidth(getText()).round() + totalspace;
      } else if ("^\u00AF".indexOf(firstchar) >= 0 && _stretchy && dynamicParts)
        return getParent().getWidth(false) - 2;
    }
    return stringWidth(getText()).round() + totalspace;
  }

  @override
  double getHeight(final bool dynamicParts) {
    return getAscentHeight(dynamicParts) + getDescentHeight(dynamicParts);
  }

  @override
  double getAscentHeight(final bool dynamicParts) {
    if (getText().length == 1 && "[()]\u222B".indexOf(getText()[0]) >= 0) {
      if (!dynamicParts || !_stretchy)
        return getFontMetrics().ascent;
      return(getExprAscentHeight() + 1);
    } else if (getText().length == 1 && "{}".indexOf(getText()[0]) >= 0) {
      if (!dynamicParts || !_stretchy)
        return getFontMetrics().ascent;
      final double ascent = getFontMetrics().ascent;
      final int countparts = (getExprHeight() / ascent).floor() + 1;

      if ("{}".indexOf(getText()[0]) >= 0)
        if (countparts % 2 == 0)
          return (countparts + 1) * ascent * 0.5 + getMiddleShift();
      return countparts * ascent * 0.5 + getMiddleShift();
    }
    else if (getText().length == 1
        && "\u2211\u220F".indexOf(getText()[0]) >= 0
        && _stretchy) {
      if (getExprHeight() > getFontMetrics().height)
        return getMathBase().getFontMetrics(getFontSize() * 2).ascent;
      else
        return getFontMetrics().ascent;
    } else if (getText().length == 1
        && "\uFE37\uFE38".indexOf(getText()[0]) >= 0)
      return 0.0;
    else if (getText() == "\u00AF" && _stretchy)
      return(3.0);
    else if (getText() == "\u223C" && _stretchy)
      return((getFontMetrics().ascent ~/ 2).toDouble());
    else if (getText() == "." || getText() == ".." || getText() == "...")
      return((getFontMetrics().ascent ~/ 2).toDouble());
    else
      return getFontMetrics().ascent;
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    if (getText().length == 1 && "[()]\u222B".indexOf(getText()[0]) >= 0) {
      if (!dynamicParts || !_stretchy)
        return getFontMetrics().descent;
      return(getExprDescentHeight() + 1);
    } else if (getText().length == 1 && "{}".indexOf(getText()[0]) >= 0) {
      if (!dynamicParts || !_stretchy)
        return getFontMetrics().descent;
      final double ascent = getFontMetrics().ascent;
      final int countparts = (getExprHeight() / ascent).floor() + 1;

      if ("{}".indexOf(getText()[0]) >= 0)
        if (countparts % 2 == 0)
          return (countparts + 1) * ascent * 0.5 - getMiddleShift();
      return countparts * ascent * 0.5 - getMiddleShift();
    }
    else if (getText().length == 1
        && "\u2211\u220F".indexOf(getText()[0]) >= 0
        && _stretchy) {
      if (getExprHeight() > getFontMetrics().height)
        return getMathBase().getFontMetrics(getFontSize() * 2).descent;
      else
        return getFontMetrics().descent;
    } else if (getText().length == 1
        && "\uFE37\uFE38".indexOf(getText()[0]) >= 0)
      return stringWidth("}");
    else
      return getFontMetrics().descent;
  }
  
}
