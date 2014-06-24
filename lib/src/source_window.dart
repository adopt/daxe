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
 * Displays the XML source code in a window.
 */
class SourceWindow {
  
  void show() {
    x.Document domdoc = doc.toDOMDoc();
    
    h.DivElement div1 = new h.DivElement();
    div1.id = 'dlg1';
    div1.classes.add('dlg1');
    
    h.DivElement divWindow = new h.DivElement();
    divWindow.classes.add('source_window');
    
    h.DivElement divContent = new h.DivElement();
    divContent.classes.add('source_content');
    addNode(domdoc, divContent);
    divWindow.append(divContent);
    
    h.DivElement divBottom = new h.DivElement();
    divBottom.classes.add('source_bottom');
    h.ButtonElement bSelect = new h.ButtonElement();
    bSelect.attributes['type'] = 'button';
    bSelect.appendText(Strings.get("source.select_all"));
    bSelect.onClick.listen((h.MouseEvent event) => selectAll());
    divBottom.append(bSelect);
    h.ButtonElement bOk = new h.ButtonElement();
    bOk.attributes['type'] = 'submit';
    bOk.appendText(Strings.get("button.Close"));
    bOk.onClick.listen((h.MouseEvent event) => close());
    divBottom.append(bOk);
    divWindow.append(divBottom);
    
    div1.append(divWindow);
    
    h.document.body.append(div1);
  }
  
  void addNode(x.Node node, h.Element html) {
    switch (node.nodeType) {
      case x.Node.DOCUMENT_NODE :
        h.SpanElement xmldec = new h.SpanElement();
        xmldec.classes.add('source_pi');
        String xmlVersion = (node as x.Document).xmlVersion;
        String xmlEncoding = (node as x.Document).xmlEncoding;
        xmldec.appendText('<?xml version="$xmlVersion" encoding="$xmlEncoding"?>');
        html.append(xmldec);
        html.appendText('\n');
        for (x.Node n=node.firstChild; n != null; n=n.nextSibling) {
          addNode(n, html);
        }
        break;
        
      case x.Node.ELEMENT_NODE :
        html.appendText('<');
        h.SpanElement elementName = new h.SpanElement();
        elementName.classes.add('source_element_name');
        elementName.appendText(node.nodeName);
        html.append(elementName);
        if (node.attributes != null) {
          for (x.Attr att in node.attributes.values) {
            html.appendText(' ');
            h.SpanElement attributeName = new h.SpanElement();
            attributeName.classes.add('source_attribute_name');
            attributeName.appendText(att.nodeName);
            html.append(attributeName);
            html.appendText('="');
            h.SpanElement attributeValue = new h.SpanElement();
            attributeValue.classes.add('source_attribute_value');
            _appendTextWithEntities(attributeValue, att.nodeValue);
            html.append(attributeValue);
            html.appendText('"');
          }
        }
        if (node.firstChild != null) {
          html.appendText('>');
          if (node.childNodes != null) {
            for (x.Node n in node.childNodes) {
              addNode(n, html);
            }
          }
          html.appendText('</');
          elementName = new h.SpanElement();
          elementName.classes.add('source_element_name');
          elementName.appendText(node.nodeName);
          html.append(elementName);
          html.appendText('>');
        } else {
          html.appendText('/>');
        }
        break;
        
      case x.Node.TEXT_NODE :
        _appendTextWithEntities(html, node.nodeValue);
        break;
      
      case x.Node.COMMENT_NODE :
        h.SpanElement span = new h.SpanElement();
        span.classes.add('source_comment');
        span.appendText(node.toString());
        html.append(span);
        break;
      
      case x.Node.ENTITY_REFERENCE_NODE :
        h.SpanElement span = new h.SpanElement();
        span.classes.add('source_entity');
        span.appendText(node.toString());
        html.append(span);
        break;
      
      case x.Node.CDATA_SECTION_NODE :
        h.SpanElement span = new h.SpanElement();
        span.classes.add('source_cdata');
        span.appendText(node.toString());
        html.append(span);
        break;
      
      case x.Node.PROCESSING_INSTRUCTION_NODE :
        h.SpanElement span = new h.SpanElement();
        span.classes.add('source_pi');
        span.appendText(node.toString());
        html.append(span);
        break;
        
      case x.Node.DOCUMENT_TYPE_NODE :
        h.SpanElement span = new h.SpanElement();
        span.classes.add('source_doctype');
        span.appendText(node.toString());
        html.append(span);
        break;
      
      default :
        html.appendText(node.toString());
        break;
    }
  }
  
  void _appendTextWithEntities(h.Element html, String s) {
    Map<String, String> cent = <String, String>{
      '&' : '&amp;',
      '"' : '&quot;',
      '<' : '&lt;',
      '>' : '&gt;'
    };
    Iterable<String> keys = cent.keys;
    int p = 0;
    while (p < s.length) {
      String c = s[p];
      if (keys.contains(c)) {
        if (p > 0)
          html.appendText(s.substring(0, p));
        h.SpanElement entity = new h.SpanElement();
        entity.classes.add('source_entity');
        entity.appendText(cent[c]);
        html.append(entity);
        s = s.substring(p + 1);
        p = 0;
      } else
        p++;
    }
    if (s.length > 0)
      html.appendText(s);
  }
  
  void close() {
    h.DivElement div1 = h.document.getElementById('dlg1');
    div1.remove();
    page.focusCursor();
  }
  
  void selectAll() {
    h.Selection selection = h.window.getSelection();
    h.Range r = new h.Range();
    r.selectNodeContents(h.querySelector('.source_content'));
    selection.removeAllRanges();
    selection.addRange(r);
  }
}
