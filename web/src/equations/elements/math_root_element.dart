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
 * The root element for creating a MathElement tree
 */
class MathRootElement extends MathElement {
  
  /** The XML element from this class */
  static final String ELEMENT = "math"; 

  /** Attribute name of the mode property */
  static final String ATTRIBUTE_MODE = "mode";

  /** Inline mathematical expression */
  static final int INLINE = 0;

  /** Non inline mathematical expression */
  static final int DISPLAY = 1;

  int _mode = INLINE;

  bool _debug = false;

  
  MathRootElement() : super();
  
  
  /**
   * Set the type of equation
   *
   * @param mode INLINE|DISPLAY
   */
  void setMode(final int mode) {
    if ((mode==INLINE) || (mode==DISPLAY))
        this._mode = mode;
  }

  /**
   * Returns the mode
   *
   * @return Display mode
   */
  int getMode() { 
    return _mode;
  }
  
  /**
   * Enables, or disables the debug mode
   *
   * @param debug Debug mode
   */
  void setDebug(final bool debug) {
    this._debug = debug;
  }
  
  /**
   * Indicates, if the debug mode is enabled
   *
   * @return True, if the debug mode is enabled
   */
  bool isDebug() {
    return _debug;
  }
  
  /**
   * Paints this component and all of its elements
   *
   * @param g The graphics context to use for painting
   */
  void paintComponent(final h.CanvasRenderingContext2D context) {
    if (_debug) {
      context.strokeStyle = 'blue';
      
      context.beginPath();
      
      context.moveTo(0, 0);
      context.lineTo(getComponentWidth() - 1, 0);
      
      context.moveTo(getComponentWidth() - 1, 0);
      context.lineTo(getComponentWidth() - 1, getComponentHeight() - 1);
      
      context.moveTo(0, 0);
      context.lineTo(0, getComponentHeight() - 1);
      
      context.moveTo(0, getComponentHeight() - 1);
      context.lineTo(getComponentWidth() - 1, getComponentHeight() - 1);
  
      context.stroke();
      
      context.strokeStyle = 'cyan';
      context.moveTo(0, getComponentHeight() / 2);
      context.lineTo(getComponentWidth() - 1, getComponentHeight() / 2);
      context.stroke();
      
      context.strokeStyle = 'black';
    }
    
    if (getMathElement(0) != null) {
      final double ha = getMathElement(0).getAscentHeight(true) - getMiddleShift();
      final double hb = getMathElement(0).getDescentHeight(true) + getMiddleShift();
      if (ha >= hb)
        paint(context, 0.0, getAscentHeight(true));
      else
        paint(context, 0.0, hb + getMiddleShift());
    }
  }
  
  /**
   * Return the current width of this component
   *
   * @return Width
   */
  int getComponentWidth() {
    return getWidth(true).ceil();
  }
  
  /**
   * Return the current height of this component
   *
   * @return Height
   */
  int getComponentHeight() {
    return getHeight(true).ceil();
  }
  
  @override
  void paint(final h.CanvasRenderingContext2D context, final double posX, final double posY) {
    if (getMathElement(0) != null)
      getMathElement(0).paint(context, posX, posY);
  }

  @override
  double getWidth(final bool dynamicParts) {
    if (getMathElement(0) == null)
      return 0.0;

    return getMathElement(0).getWidth(true) + 1;
  }

  @override
  double getHeight(final bool dynamicParts) {
    if (getMathElement(0) == null)
      return 0.0;

    if (_mode == DISPLAY)
      return getMathElement(0).getHeight(true) + 2;
    
    // CSS vertical-align:middle
    // baseline + height('x')/2
    final double ha = getMathElement(0).getAscentHeight(true) - getMiddleShift();
    final double hb = getMathElement(0).getDescentHeight(true) + getMiddleShift();
    return max(ha, hb) * 2;
  }

  @override
  double getAscentHeight(final bool dynamicParts) {
    if (getMathElement(0) == null)
      return 0.0;

    if (_mode == DISPLAY)
      return getMathElement(0).getAscentHeight(true);
    
    return max(getMathElement(0).getAscentHeight(true),
        getMathElement(0).getDescentHeight(true));
  }

  @override
  double getDescentHeight(final bool dynamicParts) {
    if (getMathElement(0) == null)
      return 0.0;

    if (_mode == DISPLAY)
      return getMathElement(0).getDescentHeight(true);
    
    return max(getMathElement(0).getAscentHeight(true),
        getMathElement(0).getDescentHeight(true));
  }
  
}

