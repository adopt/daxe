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

part of daxe;

/**
 * This class represents a GUI for an XML node. The subclasses offer differents GUIs.
 */
abstract class DaxeNode {
  static const int ELEMENT_NODE = 1;
  static const int TEXT_NODE = 3;
  static const int CDATA_SECTION_NODE = 4;
  static const int PROCESSING_INSTRUCTION_NODE = 7;
  static const int COMMENT_NODE = 8;
  static const int DOCUMENT_NODE = 9;
  
  static const String STYLE_BOLD = 'GRAS';
  static const String STYLE_ITALIC = 'ITALIQUE';
  static const String STYLE_SUPERSCRIPT = 'EXPOSANT';
  static const String STYLE_SUBSCRIPT = 'INDICE';
  static const String STYLE_UNDERLINE = 'SOULIGNE';
  static const String STYLE_STRIKETHROUGH = 'BARRE';
  static const String STYLE_BACKGROUND_COLOR = 'FCOULEUR';
  static const String STYLE_FOREGROUND_COLOR = 'PCOULEUR';
  static const String COLOR_PATTERN = "^.*\\[(x[0-9a-fA-F]{2}|[0-9]{1,3}),(x[0-9a-fA-F]{2}|[0-9]{1,3}),(x[0-9a-fA-F]{2}|[0-9]{1,3})\\]\$";

  x.Element ref; // schema element
  String _id;
  DaxeNode parent;
  int nodeType;
  String _namespaceURI;
  String prefix;
  String localName;
  String nodeValue;
  DaxeNode firstChild;
  DaxeNode nextSibling;
  List<DaxeAttr> attributes;
  bool userCannotRemove = false; // with suppr/del, could be extended to selections...
  bool valid;
  
  
  DaxeNode.fromNode(x.Node node, DaxeNode parent, [bool createChildren = true]) {
    _id = doc.newId(this);
    this.parent = parent;
    nodeType = node.nodeType;
    _namespaceURI = node.namespaceURI;
    prefix = node.prefix;
    localName = node.localName;
    if (nodeType == DaxeNode.TEXT_NODE || nodeType == DaxeNode.COMMENT_NODE ||
        nodeType == CDATA_SECTION_NODE || nodeType == PROCESSING_INSTRUCTION_NODE)
      nodeValue = node.nodeValue;
    attributes = new List<DaxeAttr>();
    LinkedHashMap<String, x.Attr> nm = node.attributes;
    if (nm != null) {
      for (x.Node n in nm.values) {
        attributes.add(new DaxeAttr.fromNode(n));
      }
    }
    if (node is x.Element)
      ref = doc.cfg.getElementRef(node as x.Element, parent == null ? null : parent.ref);
    
    if (createChildren) {
      if (node.childNodes != null) {
        DaxeNode prev = null;
        for (x.Node n in node.childNodes) {
          DaxeNode dn = NodeFactory.createFromNode(n, this);
          if (prev == null)
            firstChild = dn;
          else
            prev.nextSibling = dn;
          prev = dn;
        }
      }
    }
    if (nodeType == DaxeNode.ELEMENT_NODE)
      valid = doc.cfg.elementIsValid(this);
    else
      valid = true;
  }
  
  DaxeNode.fromRef(x.Element elementRef) {
    ref = elementRef;
    _id = doc.newId(this);
    parent = null;
    nodeType = ELEMENT_NODE;
    _namespaceURI = doc.cfg.elementNamespace(ref);
    prefix = doc.cfg.elementPrefix(ref);
    localName = doc.cfg.elementName(ref);
    nodeValue = null;
    firstChild = null;
    nextSibling = null;
    attributes = new List<DaxeAttr>();
    valid = true;
  }
  
  DaxeNode.fromNodeType(int nodeType) {
    ref = null;
    _id = doc.newId(this);
    parent = null;
    this.nodeType = nodeType;
    _namespaceURI = null;
    prefix = null;
    localName = null;
    nodeValue = null;
    firstChild = null;
    nextSibling = null;
    attributes = new List<DaxeAttr>();
    valid = true;
  }
  
  DaxeNode.text(String value) {
    _id = doc.newId(this);
    parent = null;
    nodeType = DaxeNode.TEXT_NODE;
    _namespaceURI = null;
    this.prefix = null;
    this.localName = null;
    nodeValue = value;
    firstChild = null;
    nextSibling = null;
    attributes = null;
    valid = true;
  }
  
  String get id {
    return(_id);
  }
  
  h.Element getHTMLNode() {
    return(h.document.getElementById(_id));
  }
  
  /**
   * Returns the HTML element in which the contents of the XML element will be displayed.
   * This is used in Position to find where to display the cursor when there is no child.
   */
  h.Element getHTMLContentsNode() {
    h.Element hn = getHTMLNode();
    if (hn != null && !hn.nodes.isEmpty && hn.nodes.first is h.Element)
      hn = hn.nodes.first;
    return(hn);
  }
  
  String get nodeName {
    if (nodeType == TEXT_NODE)
      return('#text');
    StringBuffer buff = new StringBuffer();
    if (prefix != null) {
      buff.write(prefix);
      buff.write(":");
    }
    buff.write(localName);
    return(buff.toString());
  }
  
  int get offsetLength {
    if (nodeType == TEXT_NODE)
      return(nodeValue.length);
    int n = 0;
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling)
      n++;
    return(n);
  }
  
  List<DaxeNode> get childNodes {
    List<DaxeNode> list = new List<DaxeNode>();
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      list.add(dn);
    }
    return(list);
  }
  
  DaxeNode get previousSibling {
    if (parent == null)
      return(null);
    for (DaxeNode dn = parent.firstChild; dn != null; dn = dn.nextSibling) {
      if (dn.nextSibling == this)
        return(dn);
    }
    return(null);
  }
  
  DaxeNode get lastChild {
    for (DaxeNode dn = firstChild; dn != null; dn = dn.nextSibling) {
      if (dn.nextSibling == null)
        return(dn);
    }
    return(null);
  }
  
  int offsetOf(DaxeNode dn) {
    int i = 0;
    for (DaxeNode n=firstChild; n != null; n=n.nextSibling) {
      if (n == dn)
        return(i);
      i++;
    }
    assert(false);
  }
  
  String getAttribute(String name) {
    for (DaxeAttr att in attributes) {
      if (att.localName == name)
        return(att.value);
    }
    return(null);
  }
  
  void setAttribute(String name, String value) {
    for (DaxeAttr att in attributes) {
      if (att.localName == name) {
        att.value = value;
        return;
      }
    }
    attributes.add(new DaxeAttr(name, value));
    return;
  }
  
  DaxeAttr getAttributeNode(String name) {
    for (DaxeAttr att in attributes) {
      if (att.localName == name)
        return(att);
    }
    return(null);
  }
  
  LinkedHashMap<String, DaxeAttr> getAttributesMapCopy() {
    LinkedHashMap<String, DaxeAttr> map = new LinkedHashMap<String, DaxeAttr>();
    for (DaxeAttr attr in attributes)
      map[attr.name] = new DaxeAttr.clone(attr);
    return(map);
  }
  
  h.Element html();
  
  /**
   * Update the display. By default, this recreates all the HTML.
   */
  void updateHTML() {
    h.Element vel = getHTMLNode();
    if (vel == null)
      return;
    h.Element nel = html();
    vel.replaceWith(nel);
  }
  
  /**
   * Update the display after children changed (insert/removal/other).
   * This method can be overriden for optimization.
   */
  void updateHTMLAfterChildrenChange(List<DaxeNode> changed) {
    List<DaxeNode> children = childNodes;
    for (DaxeNode child in changed) {
      h.Element hn = child.getHTMLNode();
      if (!children.contains(child)) {
        // removal
        if (hn != null)
          hn.remove();
        else {
          // no reference to the HTML node, only the derived class
          // could know how to remove the child display
          updateHTML();
          return;
        }
      } else if (hn == null) {
        // insert
        DaxeNode next = child.nextSibling;
        h.Node nextHn = null;
        while (nextHn == null && next != null) {
          nextHn = next.getHTMLNode();
          if (nextHn == null)
            next = next.nextSibling;
        }
        DaxeNode prev = child.previousSibling;
        h.Node prevHn = null;
        while (prevHn == null && prev != null) {
          prevHn = prev.getHTMLNode();
          if (prevHn == null)
            prev = prev.previousSibling;
        }
        if (nextHn != null) {
          nextHn.parent.insertBefore(child.html(), nextHn);
        } else if (prevHn != null) {
          prevHn.parent.append(child.html());
        } else {
          // no sibling, there might not even be a content div...
          //TODO getHTMLContentsNode
          updateHTML();
          return;
        }
      } else {
        // change
        child.updateHTML();
      }
    }
  }
  
  /**
   * The attributes have changed, an update might be needed.
   * This method can be overriden for optimization.
   */
  void updateAttributes() {
    updateHTML();
  }
  
  void setSelected(bool select) {
    if (select)
      getHTMLNode().classes.add('selected');
    else
      getHTMLNode().classes.remove('selected');
  }
  
  void appendChild(DaxeNode dn) {
    DaxeNode lastChild = firstChild;
    if (lastChild != null)
      while (lastChild.nextSibling != null)
        lastChild = lastChild.nextSibling;
    if (lastChild != null)
      lastChild.nextSibling = dn;
    else
      firstChild = dn;
    dn.parent = this;
  }
  
  void insertBefore(DaxeNode newdn, DaxeNode beforedn) {
    assert(beforedn == null || this == beforedn.parent);
    newdn.parent = this;
    DaxeNode dn = firstChild;
    if (dn == beforedn) {
      DaxeNode save = firstChild;
      firstChild = newdn;
      newdn.nextSibling = save;
    } else {
      while (dn != null && dn.nextSibling != beforedn) {
        dn = dn.nextSibling;
      }
      assert(dn != null);
      assert(dn.nextSibling == beforedn);
      DaxeNode save = dn.nextSibling;
      dn.nextSibling = newdn;
      newdn.nextSibling = save;
    }
  }
  
  void insertAfter(DaxeNode newdn, DaxeNode afterdn) {
    assert(this == afterdn.parent);
    if (afterdn.nextSibling == null)
      appendChild(newdn);
    else
      insertBefore(newdn, afterdn.nextSibling);
  }
  
  void removeChild(DaxeNode dn) {
    if (dn.previousSibling != null)
      dn.previousSibling.nextSibling = dn.nextSibling;
    if (dn == firstChild)
      firstChild = dn.nextSibling;
    dn.parent = null;
    dn.nextSibling = null;
  }
  
  void replaceWith(DaxeNode dn) {
    if (parent.firstChild == this)
      parent.firstChild = dn;
    else
      previousSibling.nextSibling = dn;
    dn.parent = parent;
    dn.nextSibling = nextSibling;
    parent = null;
    nextSibling = null;
  }
  
  void normalize() {
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      while (dn.nodeType == TEXT_NODE && dn.nextSibling != null &&
          dn.nextSibling.nodeType == TEXT_NODE) {
        dn.nodeValue = "${dn.nodeValue}${dn.nextSibling.nodeValue}";
        removeChild(dn.nextSibling);
      }
    }
  }
  
  void insertString(Position pos, String s) {
    assert(pos.dn == this && (nodeType == DaxeNode.TEXT_NODE || nodeType == DaxeNode.COMMENT_NODE));
    String v = nodeValue;
    if (v == null)
      v = '';
    nodeValue = "${v.substring(0, pos.dnOffset)}$s${v.substring(pos.dnOffset)}";
  }
  
  void remove(Position pos, int length) {
    if (nodeType == ELEMENT_NODE) {
      for (int i=pos.dnOffset; i<length; i++) {
        removeChild(childAtOffset(pos.dnOffset));
      }
    } else {
      String v = nodeValue;
      String s1 = v.substring(0, pos.dnOffset);
      String s2 = v.substring(pos.dnOffset + length);
      nodeValue = "$s1$s2";
    }
  }
  
  DaxeNode cut(int offset) {
    assert(nodeType == TEXT_NODE);
    String s1 = nodeValue.substring(0, offset);
    String s2 = nodeValue.substring(offset);
    nodeValue = s1;
    DaxeNode newjn = new DNText(s2);
    parent.insertBefore(newjn, nextSibling);
    return(newjn);
  }
  
  DaxeNode childAtOffset(int offset) {
    assert(nodeType != TEXT_NODE);
    int n = 0;
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      if (n == offset)
        return(dn);
      n++;
    }
    return(null);
  }
  
  /**
   * Add a newline after this element when serializing.
   * If it returns true, fixLineBreaks() is usually called in the fromNode constructor.
   */
  bool newlineAfter() {
    return(false);
  }
  
  /**
   * Add a newline after the start tag and if necessary a newline before the end tag
   * in this element when serializing.
   * If it returns true, fixLineBreaks() is usually called in the fromNode constructor.
   */
  bool newlineInside() {
    return(false);
  }
  
  /**
   * Remove newlines that will be added at serialization.
   */
  void fixLineBreaks() {
    if (newlineInside() && firstChild != null && firstChild is DNText) {
      String s = firstChild.nodeValue;
      if (s.startsWith('\n')) {
        if (s.length == 1)
          removeChild(firstChild);
        else
          firstChild.nodeValue = s.substring(1);
      }
    }
    DaxeNode lastNotText = lastChild;
    while (lastNotText != null && lastNotText is DNText)
      lastNotText = lastNotText.previousSibling;
    if (newlineInside() && lastChild is DNText && (lastNotText == null || !lastNotText.newlineAfter())) {
      String s = lastChild.nodeValue;
      if (s.endsWith('\n')) {
        if (s.length == 1)
          removeChild(lastChild);
        else
          lastChild.nodeValue = s.substring(0, s.length - 1);
      }
    }
    for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
      if (dn.newlineAfter() && dn.nextSibling is DNText) {
        String s = dn.nextSibling.nodeValue;
        if (s.startsWith('\n')) {
          if (s.length == 1)
            removeChild(dn.nextSibling);
          else
            dn.nextSibling.nodeValue = s.substring(1);
        }
      }
    }
  }
  
  String toString() {
    StringBuffer sb = new StringBuffer();
    switch (nodeType) {
      case DOCUMENT_NODE :
        for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
          sb.write(dn.toString());
        }
        break;
        
      case ELEMENT_NODE :
        sb.write('<');
        if (prefix != null) {
          sb.write(prefix);
          sb.write(':');
        }
        sb.write(localName);
        for (DaxeAttr att in attributes) {
          sb.write(' ');
          sb.write(att.toString());
        }
        if (newlineInside() || firstChild != null) {
          sb.write('>');
          if (newlineInside())
            sb.write('\n');
          for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
            sb.write(dn.toString());
          }
          DaxeNode lastNotText = lastChild;
          while (lastNotText != null && lastNotText is DNText)
            lastNotText = lastNotText.previousSibling;
          if (newlineInside() && lastChild != null && (lastNotText == null || !lastNotText.newlineAfter()))
            sb.write('\n');
          sb.write('</');
          if (prefix != null) {
            sb.write(prefix);
            sb.write(':');
          }
          sb.write(localName);
          sb.write('>');
        } else {
          sb.write('/>');
        }
        if (newlineAfter())
          sb.write('\n');
        break;
        
      case TEXT_NODE :
        sb.write(escape(nodeValue));
        break;
      
      case CDATA_SECTION_NODE :
        sb.write('<![CDATA[');
        sb.write(nodeValue);
        sb.write(']]>');
        break;
      
      case PROCESSING_INSTRUCTION_NODE :
        sb.write('<?');
        sb.write(nodeName);
        sb.write(' ');
        sb.write(nodeValue);
        sb.write('?>');
        break;
      
      case COMMENT_NODE :
        sb.write('<!--');
        sb.write(nodeValue);
        sb.write('-->');
        break;
    }
    return(sb.toString());
  }
  
  static String escape(String s) {
    s = s.replaceAll('&', '&amp;');
    s = s.replaceAll('"', '&quot;');
    //s = s.replaceAll("'", '&apos;');
    s = s.replaceAll('<', '&lt;');
    s = s.replaceAll('>', '&gt;');
    return(s);
  }
  
  void updateValidity() {
    valid = doc.cfg.elementIsValid(this);
    h.Element hel = getHTMLNode();
    if (hel == null)
      return;
    if (valid && hel.classes.contains('invalid'))
      hel.classes.remove('invalid');
    else if (!valid && !hel.classes.contains('invalid'))
      hel.classes.add('invalid');
  }
  
  void attributeDialog([ActionFunction okfct]) {
    AttributeDialog dlg = new AttributeDialog(this, okfct);
    dlg.show();
  }
  
  Position findPosition(num x, num y) {
    // we assume the click was in this element
    
    /*
     I wish I could use Range, like this:
     if (document.caretRangeFromPoint) {
       range = document.caretRangeFromPoint(e.pageX, e.pageY);
     } else if (e.rangeParent) {
       range = document.createRange();
       range.setStart(e.rangeParent, e.rangeOffset);
     }
     but caretRangeFromPoint does not work in Firefox, and rangeParent/rangeOffset
     do not exist in Dart...
     cf http://stackoverflow.com/q/3189812/438970
     */
    Position pos = new Position(this, 0);
    
    if (nodeType == ELEMENT_NODE || nodeType == DOCUMENT_NODE) {
      for (DaxeNode dn=firstChild; dn != null; dn=dn.nextSibling) {
        // hnx1, hny1, lineHeight: first char in HTML element
        // hnx2, hny2, lineHeight: last char
        h.Element hn = dn.getHTMLNode();
        if (hn == null)
          continue;
        double hnx1, hny1, hnx2, hny2;
        double lineHeight;
        if (hn is h.DivElement && hn.nodes.first is h.SpanElement &&
            hn.nodes.last is h.SpanElement) {
          // this is an optimization, to avoid appending too many spans
          h.Element span_test = hn.nodes.first;
          h.Rect box = span_test.getBoundingClientRect();
          hnx1 = box.left;
          hny1 = box.top;
          lineHeight = span_test.offset.height.toDouble();
          span_test = hn.nodes.last;
          box = span_test.getBoundingClientRect();
          hnx2 = box.right;
          hny2 = box.bottom;
        } else if (hn is h.TableCellElement || hn is h.TableRowElement ||
            hn is h.TableElement || hn is h.ImageElement || hn.classes.contains('form')) {
          h.Rect box = hn.getBoundingClientRect();
          hnx1 = box.left;
          hny1 = box.top;
          if (hn.classes.contains('form')) // FIXME: this is a hack !
            hnx2 = hn.query('table').getBoundingClientRect().right;
          else
            hnx2 = box.right;
          hny2 = box.bottom;
          lineHeight = box.height;
        } else {
          // note: for a span, getBoundingClientRect can return a wrong bottom when
          // there are \n inside, so we can't even use this on hn to avoid
          // appending unecessary spans
          h.Element span_test = new h.Element.tag('span');
          span_test.append(new h.Text("|"));
          if (hn.nodes.isEmpty)
            hn.append(span_test);
          else
            hn.insertBefore(span_test, hn.nodes.first);
          h.Rect box = span_test.getBoundingClientRect();
          hnx1 = box.left;
          hny1 = box.top;
          lineHeight = span_test.offset.height.toDouble();
          span_test.remove();
          hn.append(span_test);
          box = span_test.getBoundingClientRect();
          hnx2 = box.left;
          hny2 = box.bottom;
          span_test.remove();
        }
        if ((y < hny1 + lineHeight && (y < hny1 || (x < hnx1 && hn is! h.LIElement)))) {
          // position is before this child
          return(pos);
        }
        if (y > hny2 - lineHeight && (y > hny2 || (x > hnx2 && hn is! h.LIElement))) {
          // position is after this child
          pos = new Position(this, offsetOf(dn) + 1);
        } else {
          // position is within this child
          pos = dn.findPosition(x, y);
          return(pos);
        }
      }
    } else if (nodeType == TEXT_NODE) {
      /* doesn't work with other browsers than Chrome...
      h.Range range = h.document.$dom_caretRangeFromPoint(x, y);
      h.Element hn = getHTMLNode();
      if (range.startContainer == hn || range.startContainer == hn.$dom_firstChild)
        return(new Position(this, range.startOffset));
      */
      int pp = 0; // position in the XML node
      for (h.Node hn in getHTMLNode().nodes) {
        h.Text ht;
        if (hn is h.Text)
          ht = hn;
        else if (hn is h.Element) // selection span
          ht = hn.nodes.first;
        else
          continue;
        h.Range range = new h.Range();
        for (int i=0; i<ht.length; i++) {
          // problem: depending on the browser, the clientrects are not the same
          // for \n or for line-breaking space characters...
          if (nodeValue[pp + i] != '\n') {
            range.setStart(ht, i);
            range.setEnd(ht, i+1);
            List<h.Rect> rects = range.getClientRects();
            for (h.Rect r in rects) {
              if (i < nodeValue.length - 1 && r.left == r.right &&
                  x < r.left && y < r.bottom) {
                //print("left of line start after newline");
                return(new Position(this, pp + i+1));
              } if (x < r.right && y <= r.bottom) {
                if (x < (r.left + r.right) / 2)
                  return(new Position(this, pp + i));
                else
                  return(new Position(this, pp + i+1));
              } else if (y < r.top - 5) {
                //print("line above");
                // the point is on the line above
                if (pp+i == 0 || nodeValue[pp+i] == ' ')
                  return(new Position(this, pp + i));
                else
                  return(new Position(this, pp + i - 1));
              }
            }
          } else {
            // ranges are not reliable for positions of newline characters
            String s = ht.text;
            ht.text = "${s.substring(0, i)}|${s.substring(i)}";
            range.setStart(ht, i);
            range.setEnd(ht, i+1);
            List<h.Rect> rects = range.getClientRects();
            ht.text = s;
            for (h.Rect r in rects) {
              if (x > r.left && y <= r.bottom) {
                //print("right of \\n");
                // to the right of the last character on the line
                return(new Position(this, pp + i));
              }
            }
          }
        }
        pp += ht.length;
      }
      // not found...
      //print("position not found");
    }
    return(new Position(this, offsetLength));
  }
  
  Position firstCursorPositionInside() {
    return(new Position(this, 0));
  }
  
  Position lastCursorPositionInside() {
    return(new Position(this, offsetLength));
  }
  
  void setStyle(h.Element hn) {
    String styleParam = doc.cfg.elementParameterValue(ref, 'style', null);
    if (styleParam != null) {
      List<String> styleList = styleParam.split(';');
      for (String style in styleList) {
        if (style == STYLE_BOLD) {
          hn.style.fontWeight = 'bold';
        } else if (style == STYLE_ITALIC) {
          hn.style.fontStyle = 'italic';
        } else if (style == STYLE_SUPERSCRIPT) {
          hn.style.verticalAlign = 'super';
          hn.style.fontSize = '80%';
        } else if (style == STYLE_SUBSCRIPT) {
          hn.style.verticalAlign = 'sub';
          hn.style.fontSize = '80%';
        } else if (style == STYLE_UNDERLINE) {
          hn.style.textDecoration = 'underline';
        } else if (style == STYLE_STRIKETHROUGH) {
          hn.style.textDecoration = 'line-through';
        } else if (style.startsWith(STYLE_BACKGROUND_COLOR)) {
          hn.style.background = _getColor(style);
        } else if (style.startsWith(STYLE_FOREGROUND_COLOR)) {
          hn.style.color = _getColor(style);
        }
      }
    }
    String fontParam = doc.cfg.elementParameterValue(ref, 'police', null);
    if (fontParam != null) {
      if (fontParam == 'Monospaced')
        fontParam = 'monospace';
      hn.style.fontFamily = fontParam;
    }
    String sizeParam = doc.cfg.elementParameterValue(ref, 'taille', null);
    if (sizeParam != null) {
      hn.style.fontSize = sizeParam;
    }
  }
  
  String _getColor(String style) {
    Iterable<Match> matches = COLOR_PATTERN.allMatches(style);
    for (Match m in matches) {
      final List<int> color = new List<int>();
      for (int j = 0; j < 3; j++) {
        String value = m.group(j + 1);
        if (value.startsWith("x"))
          color[j] = int.parse(value.substring(1), radix: 16);
        else
          color[j] = int.parse(value);
      }
      return("rgb(${color[0]}, ${color[1]}, ${color[2]})");
    }
    return(null);
  }
}
