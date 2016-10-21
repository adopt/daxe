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
 * The basic class the the math elements. From this class elements inherits.
 */
class MathElement {

  /** The URI from MathML */
  static final String URI = "http://www.w3.org/1998/Math/MathML";

  MathBase base;
  MathElement parent;
  int fontsize = 14;
  final List<MathElement> children = new List<MathElement>();

  final StringBuffer text = new StringBuffer();

  /**
   * Creates a math element
   *
   * [base]: the base for the math element tree;
   * [fontsize]: the font size for this element.
   */
  MathElement([final MathBase base, final int fontsize]) {
    if (base != null)
      setMathBase(base);
    if (fontsize != null)
      setFontSize(fontsize);
  }
  
  /**
   * Add a math element as a child
   */
  void addMathElement(final MathElement child) {
    if (child != null) {
      children.add(child);
      child.setMathBase(base);
      child.setParent(this);
      child.setFontSize(fontsize);
    }
  }

  /**
   * Gets a child from this element.
   *
   * [index]: index of the child.
   */
  MathElement getMathElement(final int index) {
    if ((index >= 0) && (index < children.length))
      return children[index];
    return null;
  }

  /**
   * Sets a child from this element
   *
   * [index]: index of the child.
   */
  void setMathElementAt(final MathElement child, final int index) {
    if ((index >= 0) && (index < children.length))
      children[index] = child;
  }

  /**
   * Returns the count of children from this element
   */
  int getMathElementCount() {
    return children.length;
  }

  /**
   * Add the content of a String to this element
   */
  void addText(final String text) {
    for (int i = 0; i < text.length; i++)
      if (" \t\n\r".indexOf(text[i]) < 0)
        this.text.write(text[i]);
      else if ((' ' == text[i]) && (i>0) && (' ' != text[i - 1]))
        this.text.write(text[i]);
  }

  /**
   * Returns the text content of this element
   */
  String getText() {
    return text.toString().trim();
  }

  /**
   * Sets the base for this element
   */
  void setMathBase(final MathBase base) {
    this.base = base;
    for (final MathElement e in children)
      e.setMathBase(base);
  }

  /**
   * Gets the math base
   */
  MathBase getMathBase() {
    return base;
  }

  /**
   * Sets the parent of this element
   */
  void setParent(final MathElement parent) {
    this.parent = parent;
  }

  /**
   * Returns get parent of this element
   */
  MathElement getParent() {
    return parent;
  }

  /**
   * Sets the font size for this component
   */
  void setFontSize(final int fontsize) {
    this.fontsize = max(fontsize, 8);
    for (final MathElement e in children)
      e.setFontSize(this.fontsize);
  }

  /**
   * Gets the used font size
   */
  int getFontSize() {
    return fontsize;
  }

  /**
   * Gets the used font
   */
  String getFont() {
    if (base != null)
      return base.getFont(fontsize);
    return null;
  }

  String getItalicFont() {
    if (base != null)
      return base.getFont(fontsize, MathBase.STYLE_ITALIC);
    return null;
  }

  String getBoldFont() {
    if (base != null)
      return base.getFont(fontsize, MathBase.STYLE_BOLD);
    return null;
  }

  String getBoldItalicFont() {
    if (base != null)
      return base.getFont(fontsize, MathBase.STYLE_BOLD_ITALIC);
    return null;
  }

  /**
   * Gets the font metrics of the used font
   */
  TextMetrics getFontMetrics() {
    if (base != null)
      return base.getFontMetrics(fontsize);
    return null;
  }
  
  double stringWidth(s) {
    return(base.stringWidth(s, getFont()));
  }
  
  TextMetrics getStringMetrics(String s) {
    return(new TextMetrics(s, getFont()));
  }
  
  /**
   * Paints a border around this element as debug information.
   *
   * [context]: the graphics context to use for painting;
   * [posX]: the first left position for painting;
   * [posY]: the position of the baseline.
   */
  void debug(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    context.strokeStyle = 'blue';
    context.beginPath();
    context.moveTo(posX, posY - getAscentHeight(true));
    context.lineTo(posX + getWidth(true), posY - getAscentHeight(true));
    context.moveTo(posX + getWidth(true), posY - getAscentHeight(true));
    context.lineTo(posX + getWidth(true), posY + getDescentHeight(true));
    context.moveTo(posX, posY + getDescentHeight(true));
    context.lineTo(posX + getWidth(true), posY + getDescentHeight(true));
    context.moveTo(posX, posY - getAscentHeight(true));
    context.lineTo(posX, posY + getDescentHeight(true));
    context.stroke();
    context.strokeStyle = 'red';
    context.beginPath();
    context.moveTo(posX, posY);
    context.lineTo(posX + getWidth(true), posY);
    context.stroke();
    context.strokeStyle ='black';
  }

  /**
   * Paints this element
   *
   * [context]: the graphics context to use for painting;
   * [posX]: the first left position for painting;
   * [posY]: the position of the baseline.
   */
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    if (base.isDebug())
      debug(context, posX, posY);

    double pos = posX;
    MathElement child;

    for (int i = 0; i < getMathElementCount(); i++)
    {
      child = getMathElement(i);
      child.paint(context, pos, posY);
      pos += child.getWidth(true) + 2;
    }
  }

  /**
   * Return the current width of this element.
   */
  double getWidth(final bool dynamicParts) {
    double width = 0.0;
    
    for (final MathElement e in children)
      width += e.getWidth(dynamicParts) + 2;
    return width - 2;
  }

  /**
   * Return the current height of this element
   *
   * [dynamicParts]: should be true, if the calculation consider the elements,
   * which has not fixed sizes.
   */
  double getHeight(final bool dynamicParts) {
    return getAscentHeight(dynamicParts) + getDescentHeight(dynamicParts);
  }
  
  double getRealAscentHeight() {
    return getAscentHeight(true);
  }
  
  /**
   * Return the current height of the upper part of this component from the baseline.
   *
   * [dynamicParts]: should be true, if the calculation consider the elements,
   * which has not fixed sizes.
   */
  double getAscentHeight(final bool dynamicParts) {
    double height = 0.0;

    for (final MathElement element in children)
      height = max(height, element.getAscentHeight(dynamicParts));
    
    return height;
  }

  /**
   * Return the current height of the lower part of this component from the baseline.
   *
   * [dynamicParts]: should be true, if the calculation consider the elements,
   * which has not fixed sizes.
   */
  double getDescentHeight(final bool dynamicParts) {
    double height = 0.0;

    for (final MathElement element in children)
      height = max(height, element.getDescentHeight(dynamicParts));
    
    return height;
  }

  /**
   * Returns the distance of the baseline and the middleline
   */
  double getMiddleShift() {
    return base.getFontMetrics(getFontSize()).ascent * 0.30;
    // half the height of a 'x' would be better, but we need a Graphics object to calculate that
    // (the current 0.30 factor depends on the font...)
  }
}
