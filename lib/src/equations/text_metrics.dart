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

// Someday we will use canvas' TextMetrics instead of this class
// http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#drawing-text-to-the-bitmap

class TextMetrics {
  static final canvas = new h.CanvasElement(width:500, height:300);
  double width;
  double height;
  double ascent;
  double descent;
  double actualBoundingBoxAscent;
  double actualBoundingBoxDescent;
  
  TextMetrics(final String s, final String font) {
    h.SpanElement text = new h.SpanElement();
    text.setAttribute('style', "font: $font");
    text.text = s;
    h.DivElement block = new h.DivElement();
    block.setAttribute('style', 'display: inline-block; width: 1px; height: 0px;');
    
    h.DivElement div = new h.DivElement();
    div.append(text);
    div.append(block);
    
    h.document.body.append(div);
    
    width = text.offset.width.toDouble();
    
    block.style.verticalAlign = 'bottom';
    height = (block.offset.top - text.offset.top).toDouble();
    
    block.style.verticalAlign = 'baseline';
    ascent = (block.offset.top - text.offset.top).toDouble();
    
    descent = height - ascent;
    
    div.remove();
    
    // to get the real ascent/descent, we have to use a canvas :(
    h.CanvasRenderingContext2D context = canvas.context2D;
    context.font = font;
    context.fillStyle = 'white';
    context.fillRect(0, 0, canvas.width, canvas.height);
    context.fillStyle = 'black';
    context.fillText(s, 0, ascent);
    int cw = width.ceil();
    int ch = height.ceil();
    List<int> data = context.getImageData(0, 0, cw, ch).data;
    int top1 = 0;
    bool t1 = false;
    int top2 = top1;
    int bottom1 = ch - 1;
    bool b1 = false;
    int bottom2 = bottom1;
    for (int i=0; i < cw * ch; i++) {
      if (!t1 && data[i*4] != 0xFF) {
        top1 = i ~/ cw;
        top2 = top1;
        t1 = true;
      }
      if (data[i*4] < 0x90) {
        top2 = i ~/ cw;
        break;
      }
    }
    double top = (top1 + top2) / 2;
    for (int i=cw * ch - 1; i >= 0; i--) {
      if (!b1 && data[i*4] != 0xFF) {
        bottom1 = i ~/ cw;
        bottom2 = bottom1;
        b1 = true;
      }
      if (data[i*4] < 0x90) {
        bottom2 = i ~/ cw;
        break;
      }
    }
    double bottom = (bottom1 + bottom2) / 2;
    actualBoundingBoxAscent = ascent - top;
    actualBoundingBoxDescent = bottom - ascent;
  }
  
}

