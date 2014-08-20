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
 * The graphical representation of a tag in the web page.
 */
class Tag {
  static const int START = 0;
  static const int END = 1;
  static const int EMPTY = 2;
  DaxeNode _dn;
  int _type;
  bool _long;
  
  Tag(DaxeNode dn, int type, [bool long]) {
    _dn = dn;
    _type = type;
    if (long != null)
      _long = long;
    else
      _long = false;
  }
  
  h.Element html() {
    h.Element span = new h.SpanElement();
    String classe;
    if (_type == START)
      classe = "start_tag";
    else if (_type == END)
      classe = "end_tag";
    else if (_type == EMPTY)
      classe = "empty_tag";
    span.classes.add(classe);
    if (_long)
      span.classes.add('long');
    if (_type != END) {
      bool hasAttributes;
      if (_dn.ref != null) {
        List<x.Element> attRefs = doc.cfg.elementAttributes(_dn.ref);
        hasAttributes = (attRefs != null && attRefs.length > 0);
      } else {
        hasAttributes = true; // who knows ?
      }
      if (hasAttributes) {
        h.ImageElement img = new h.ImageElement(src:'packages/daxe/images/attributes.png', width:16, height:16);
        img.onClick.listen((h.MouseEvent event) => attributeButton(event));
        span.append(img);
      }
    }
    String title;
    if (_dn.ref != null) {
      title = doc.cfg.elementTitle(_dn.ref);
      if (title == null)
        title = _dn.nodeName;
    } else if (_dn is DNComment) {
      if (_type == START)
        title = "(";
      else
        title = ")";
    } else if (_dn is DNProcessingInstruction) {
      if (_type == START)
        title = "PI ${_dn.nodeName}";
      else
        title = "PI";
    } else if (_dn is DNCData)
      title = "CDATA";
    else if (_dn.nodeName != null)
      title = _dn.nodeName;
    else
      title = "?";
    if (_type != END) {
      bool listAllAttributes = (doc.cfg.elementParameterValue(_dn.ref,
          'attributsVisibles', 'false') == 'true');
      if (listAllAttributes) {
        span.append(new h.Text(title));
        for (DaxeAttr ja in _dn.attributes) {
          span.append(new h.Text(" "));
          h.Element nom_att = new h.SpanElement();
          nom_att.attributes['class'] = 'attribute_name';
          nom_att.text = ja.localName;
          span.append(nom_att);
          span.append(new h.Text("="));
          h.Element val_att = new h.SpanElement();
          val_att.attributes['class'] = 'attribute_value';
          val_att.text = ja.value;
          span.append(val_att);
        }
      } else {
        List<String> titleAttributes = doc.cfg.getElementParameters(_dn.ref)['titreAtt'];
        if (titleAttributes != null) {
          for (String attr in titleAttributes) {
            String value = _dn.getAttribute(attr);
            if (value != null && value != '') {
              title += " '$value'";
              break;
            }
          }
        }
        span.append(new h.Text(title));
      }
    } else
      span.append(new h.Text(title));
    span.onDoubleClick.listen((h.MouseEvent event) {
      page.selectNode(_dn);
      event.preventDefault();
      event.stopPropagation();
    });
    return(span);
  }
  
  void attributeButton(h.MouseEvent event) {
    _dn.attributeDialog();
  }
}
