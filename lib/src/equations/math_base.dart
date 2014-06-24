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
 * The base for creating a MathElement tree. Based on STIX fonts.
 */
class MathBase {
  static String STIXFontRegular = 'STIXSubset-Regular';
  static String STIXFontItalic = 'STIXSubset-Italic';
  static String STIXFontBold = 'STIXSubset-Bold';
  static bool fontsLoaded = false;
  
  static const int STYLE_PLAIN = 0;
  static const int STYLE_BOLD = 1;
  static const int STYLE_ITALIC = 2;
  static const int STYLE_BOLD_ITALIC = 3;
  
  int _inlinefontsize;
  int _displayfontsize;

  final int minfontsize = 8;
  final int maxfontsize = 60;

  List<TextMetrics> _fontmetrics = null;

  bool _debug = false;

  /** Inline mathematical expression */
  static final int INLINE = 0;

  /** Non inline mathematical expression */
  static final int DISPLAY = 1;

  final int _mode = INLINE;

  MathRootElement _rootElement;
  
  h.CanvasRenderingContext2D _context;
  
  
  /**
   * Creates a MathBase
  *
   * @param element Root element of a math tree
   * @param inlinefontsize Size of the preferred font used by inline equations
   * @param displayfontsize Size of the preferred font used by non inline equations
   * @param gcalc Graphics object to use to calculate character sizes (nothing will be painted on it)
   */
  MathBase({final MathRootElement element, final int inlinefontsize:15, final int displayfontsize:16,
      final h.CanvasRenderingContext2D context}) {
    
    this._inlinefontsize = inlinefontsize;
    this._displayfontsize = displayfontsize;
    
    if (context != null)
      _fontmetrics = new List<TextMetrics>(maxfontsize);
    if (element != null)
      setRootElement(element);
    if (context != null)
      this._context = context;
  }
  
  /**
   * This should be called in advance, so that the browser is reader
   * to use the fonts when it is needed.
   */
  static void loadFonts() {
    if (fontsLoaded)
      return;
    h.CanvasElement canvas = new h.CanvasElement(width:10, height: 10);
    h.CanvasRenderingContext2D context = canvas.context2D;
    context.font = "15px $STIXFontRegular";
    context.fillText('.', 0, 0);
    context.font = "15px $STIXFontItalic";
    context.fillText('.', 0, 0);
    context.font = "15px $STIXFontBold";
    context.fillText('.', 0, 0);
    fontsLoaded = true;
  }
  
  /**
   * Set the root element of a math tree
  *
   * @param element Root element of a math tree
   */
  void setRootElement(final MathRootElement element) {
    if (element == null)
      return;
    
    _rootElement = element;
    
    _rootElement.setMathBase(this);
    
    if (element.getMode() == MathRootElement.DISPLAY)
      _rootElement.setFontSize(_displayfontsize);
    else
      _rootElement.setFontSize(_inlinefontsize);
    
    _rootElement.setDebug(isDebug());
  }

  /**
   * Enables, or disables the debug mode
   *
   * @param debug Debug mode
   */
  void setDebug(final bool debug) {
    this._debug = debug;
    if (_rootElement != null)
      _rootElement.setDebug(debug);
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
   * Sets the default font size, which used for the root element
   *
   * @param fontsize Font size
   */
  void setDefaultFontSize(final int fontsize) {
    if (fontsize >= minfontsize || fontsize < maxfontsize)
      this._inlinefontsize = fontsize;
  }

  /**
   * Get the default font size
   *
   * @return Default font size
   */
  int getDefaultInlineFontSize() {
    return _inlinefontsize;
  }

  /**
   * Sets the default font size for non inline equations
   *
   * @param fontsize Default font size
   */
  void setDefaultDisplayFontSize(final int fontsize) {
    if (fontsize >= minfontsize || fontsize < maxfontsize)
      this._displayfontsize = fontsize;
  }

  /**
   * Get the default font size for non inline equations
   *
   * @return Default display font size
   */
  int getDefaultDisplayFontSize() {
    return _displayfontsize;
  }

  /**
   * Get a font specified by the font size
   *
   * @param fontsize Font size
   *
   * @return Font
   */
  String getFont(final int fontsize, [int style=MathBase.STYLE_PLAIN]) {
    int size;
    if (fontsize < minfontsize)
      size = minfontsize;
    else if (fontsize > maxfontsize)
      size = maxfontsize;
    else
      size = fontsize;
    String sstyle, sfont;
    if (style == MathBase.STYLE_ITALIC) {
      sstyle = '';
      sfont = STIXFontItalic;
    } else if (style == MathBase.STYLE_BOLD) {
      sstyle = '';
      sfont = STIXFontBold;
    } else if (style == MathBase.STYLE_BOLD_ITALIC) {
      sstyle = 'italic';
      sfont = STIXFontBold;
    } else {
      sstyle = '';
      sfont = STIXFontRegular;
    }
    return("$sstyle ${size}px $sfont");
  }

  /**
   * Get the font metrics specified by the font size
   *
   * @param fontsize Font size
   *
   * @return Font metrics
   */
  TextMetrics getFontMetrics(final int fontsize) {
    int size;
    if (fontsize < minfontsize)
      size = minfontsize;
    else if (fontsize > maxfontsize)
      size = maxfontsize;
    else
      size = fontsize;
    if (_fontmetrics[size] == null)
      _fontmetrics[size] = createFontMetrics(getFont(fontsize));
    return _fontmetrics[size];
  }

  TextMetrics createFontMetrics(String font) {
    return(new TextMetrics('Hg', font));
  }
  
  double stringWidth(String s, String font) {
    // note: we could also use TextMetrics.width, it would be more consistent but maybe less precise...
    String save = _context.font;
    _context.font = font;
    double width = _context.measureText(s).width;
    _context.font = save;
    return(width);
  }
  
  /**
   * Paints this component and all of its elements
   *
   * @param context The graphics context to use for painting
   */
  void paint(final h.CanvasRenderingContext2D context) {
    context.clearRect(0, 0, context.canvas.width, context.canvas.height);
    if (_rootElement != null)
      _rootElement.paintComponent(context);
  }

  /**
   * Return the current width of this component
   *
   * @return Width
   */
  int getWidth() {
    if (_rootElement != null && _fontmetrics != null)
      return _rootElement.getComponentWidth();
    return 0;
  }

  /**
   * Return the current height of this component
   *
   * @return Height
   */
  int getHeight() {
    if (_rootElement != null && _fontmetrics != null)
      return _rootElement.getComponentHeight();
    return 0;
  }
  
}

