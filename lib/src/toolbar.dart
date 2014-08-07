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

class Toolbar {
  List<ToolbarItem> items;
  List<x.Element> cacheRefs = null;
  
  Toolbar([Config cfg]) {
    items = new List<ToolbarItem>();
    if (doc.saveURL != null) {
      ToolbarBox documentBox = new ToolbarBox();
      documentBox.add(new ToolbarButton(Strings.get('menu.save'), 'document_save.png',
          () => page.save()));
      items.add(documentBox);
    }
    ToolbarBox historyBox = new ToolbarBox();
    historyBox.add(new ToolbarButton(Strings.get('undo.undo'), 'history_undo.png',
        () => doc.undo(), data:"undo", enabled:false));
    historyBox.add(new ToolbarButton(Strings.get('undo.redo'), 'history_redo.png',
        () => doc.redo(), data:"redo", enabled:false));
    items.add(historyBox);
    ToolbarBox findBox = new ToolbarBox();
    findBox.add(new ToolbarButton(Strings.get('find.find_replace'), 'find.png',
        () => (new FindDialog()).show()));
    items.add(findBox);
    if (cfg != null) {
      // Buttons to insert new elements
      ToolbarBox insertBox = new ToolbarBox();
      x.Element ref = cfg.firstElementWithType('fichier');
      if (ref != null) {
        _addInsertButton(cfg, insertBox, ref, 'insert_image.png');
      }
      ref = cfg.firstElementWithType('equationmem');
      if (ref != null) {
        _addInsertButton(cfg, insertBox, ref, 'equation.png');
      }
      ref = cfg.firstElementWithType('symbole2');
      if (ref != null) {
        _addInsertButton(cfg, insertBox, ref, 'insert_symbol.png');
      }
      ref = cfg.firstElementWithType('tabletexte');
      if (ref != null) {
        _addInsertButton(cfg, insertBox, ref, 'insert_table.png');
      }
      ref = cfg.firstElementWithType('liste');
      if (ref != null) {
        _addInsertButton(cfg, insertBox, ref, 'ul.png');
      }
      items.add(insertBox);
      // List buttons
      x.Element ulRef = DNWList.ulRef();
      x.Element olRef = DNWList.olRef();
      if (ulRef != null || olRef != null) {
        ToolbarBox listBox = new ToolbarBox();
        if (ulRef != null) {
          ToolbarButton button = new ToolbarButton(_documentationFor(ulRef), 'ul.png',
              null, data:new ToolbarStyleInfo(ulRef, null, null));
          button.action = () {
            if (button.selected)
              DNWList.riseLevel();
            else
              DNWList.addList((button.data as ToolbarStyleInfo).ref);
          };
          listBox.add(button);
        }
        if (olRef != null) {
          ToolbarButton button = new ToolbarButton(_documentationFor(olRef), 'ol.png',
              null, data:new ToolbarStyleInfo(olRef, null, null));
          button.action = () {
            if (button.selected)
              DNWList.riseLevel();
            else
              DNWList.addList((button.data as ToolbarStyleInfo).ref);
          };
          listBox.add(button);
        }
        listBox.add(new ToolbarButton(Strings.get('toolbar.rise_list_level'), 'list_rise_level.png',
            () => DNWList.riseLevel(), data:'rise_list_level'));
        if (doc.cfg.isSubElement(DNWList.findItemRef(ulRef), ulRef) ||
            doc.cfg.isSubElement(DNWList.findItemRef(olRef), olRef))
          listBox.add(new ToolbarButton(Strings.get('toolbar.lower_list_level'), 'list_lower_level.png',
              () => DNWList.lowerLevel(), data:'lower_list_level'));
        items.add(listBox);
      }
      // Style buttons
      ToolbarBox styleBox = new ToolbarBox();
      List<x.Element> all = cfg.allElementsList();
      for (ref in all) {
        String dtype = cfg.elementDisplayType(ref);
        if (dtype == 'style') {
          String style = cfg.elementParameterValue(ref, 'style', null);
          if (style == 'GRAS') {
            _addStyleButton(cfg, styleBox, ref, 'style_bold.png', 'B');
          } else if (style == 'ITALIQUE') {
            _addStyleButton(cfg, styleBox, ref, 'style_italic.png', 'I');
          } else if (style == 'EXPOSANT') {
            _addStyleButton(cfg, styleBox, ref, 'style_superscript.png');
          } else if (style == 'INDICE') {
            _addStyleButton(cfg, styleBox, ref, 'style_subscript.png');
          } else if (style == 'BARRE') {
            _addStyleButton(cfg, styleBox, ref, 'style_strikethrough.png');
          } else if (style == 'SOULIGNE') {
            _addStyleButton(cfg, styleBox, ref, 'style_underline.png');
          }
        }
      }
      if (styleBox.length > 0) {
        styleBox.add(new ToolbarButton(Strings.get('toolbar.remove_styles'), 'remove_styles.png',
            () => DNStyle.removeStylesFromSelection(), data:"remove_styles"));
        items.add(styleBox);
      }
      if (doc.hiddenp != null) {
        // Align buttons
        String pStyleAtt = doc.cfg.elementParameterValue(doc.hiddenp, 'styleAtt', 'style');
        // check if style attribute is allowed for hidden paragraphs
        List<x.Element> attRefs = doc.cfg.elementAttributes(doc.hiddenp);
        bool found = false;
        for (x.Element attRef in attRefs) {
          if (doc.cfg.attributeName(attRef) == pStyleAtt) {
            found = true;
            break;
          }
        }
        if (found) {
          ToolbarBox alignBox = new ToolbarBox();
          _addParagraphCssButton(alignBox, 'text-align', 'left',
              Strings.get('toolbar.align_left'), 'align_left.png');
          _addParagraphCssButton(alignBox, 'text-align', 'right',
              Strings.get('toolbar.align_right'), 'align_right.png');
          _addParagraphCssButton(alignBox, 'text-align', 'center',
              Strings.get('toolbar.align_center'), 'align_center.png');
          _addParagraphCssButton(alignBox, 'text-align', 'justify',
              Strings.get('toolbar.align_justify'), 'align_justify.png');
          items.add(alignBox);
        }
      }
      ref = DNStyleSpan.styleSpanRef();
      if (ref != null) {
        // Font menu
        List<String> fonts = ['serif', 'sans-serif', 'cursive', 'fantasy', 'monospace'];
        ToolbarMenu tbmenu = _makeStyleToolbarMenu(Strings.get('toolbar.font'), "font-family", fonts);
        items.add(tbmenu);
        /*
        A size menu is a bad idea: larger font sizes are used for titles and it is
        important to be able to extract titles automatically
        
        // Size menu
        List<String> sizes = ['8', '9', '10', '11', '12', '14', '16', '18',
                              '20', '24', '28', '32', '36', '48', '72'];
        tbmenu = _makeStyleToolbarMenu(Strings.get('toolbar.size'), "font-size", sizes, "px");
        items.add(tbmenu);
        */
      }
    }
  }
  
  ToolbarMenu _makeStyleToolbarMenu(String title, String cssName, List<String> cssValues,
                                    [String cssUnit]) {
    Menu menu = new Menu(title);
    x.Element styleRef = DNStyleSpan.styleSpanRef();
    for (String cssValue in cssValues) {
      String cssValueWithUnit = cssValue;
      if (cssUnit != null)
        cssValueWithUnit += cssUnit;
      String css = "$cssName: $cssValueWithUnit";
      MenuItem menuItem = new MenuItem(cssValue, null,
          data:new ToolbarStyleInfo(styleRef, cssName, cssValueWithUnit));
      menuItem.action = () {
        if (menuItem.checked) {
          Position start = page.getSelectionStart();
          Position end = page.getSelectionEnd();
          if (start == end && start.dn is DNText && start.dn.parent.ref == styleRef &&
              (start.dn.parent as DNStyle).css == css &&
              start.dnOffset == start.dn.offsetLength && start.dn.nextSibling == null) {
            // we are at the end of the style
            // just move the cursor position outside of the style
            DaxeNode styleNode = start.dn.parent;
            page.moveCursorTo(new Position(styleNode.parent, styleNode.parent.offsetOf(styleNode)+1));
            page.updateAfterPathChange();
          } else
            DNStyle.removeStylesFromSelection(styleRef, cssName);
        } else {
          DNStyle.removeAndApplyStyleToSelection(styleRef, cssName, css);
        }
      };
      menu.add(menuItem);
    }
    ToolbarMenu tbmenu = new ToolbarMenu(menu);
    return(tbmenu);
  }
  
  String _documentationFor(x.Element ref) {
    String documentation = doc.cfg.documentation(ref);
    if (documentation == null)
      documentation = doc.cfg.elementTitle(ref);
    return(documentation);
  }
  
  _addInsertButton(Config cfg, ToolbarBox box, x.Element ref, String icon) {
    ToolbarButton button = new ToolbarButton(_documentationFor(ref), icon,
        () => doc.insertNewNode(ref, 'element'),
        data:new ToolbarStyleInfo(ref, null, null));
    box.add(button);
  }
  
  _addStyleButton(Config cfg, ToolbarBox box, x.Element ref, String icon, [String shortcut=null]) {
    ToolbarButton button = new ToolbarButton(_documentationFor(ref), icon, null,
        data:new ToolbarStyleInfo(ref, null, null), shortcut:shortcut);
    button.action = () {
      if (button.selected) {
        Position start = page.getSelectionStart();
        Position end = page.getSelectionEnd();
        if (start == end && start.dn is DNText && start.dn.parent.ref == ref &&
            start.dnOffset == start.dn.offsetLength && start.dn.nextSibling == null) {
          // we are at the end of the style
          // just move the cursor position outside of the style
          DaxeNode styleNode = start.dn.parent;
          page.moveCursorTo(new Position(styleNode.parent, styleNode.parent.offsetOf(styleNode)+1));
          page.updateAfterPathChange();
        } else
          DNStyle.removeStylesFromSelection(ref);
      } else {
        DNStyle.applyStyleInsideSelection(ref);
      }
    };
    box.add(button);
  }
  
  _addParagraphCssButton(ToolbarBox alignBox, String cssName, String cssValue,
                         String title, String icon) {
    ToolbarButton button = new ToolbarButton(title, icon,
        null, data:new ToolbarStyleInfo(doc.hiddenp, cssName, cssValue));
    button.action = () {
      if (button.selected) {
        DNHiddenP.removeStyleFromSelection(cssName);
      } else {
        DNHiddenP.applyStyleToSelection(cssName, '$cssName: $cssValue');
      }
    };
    alignBox.add(button);
  }
  
  add(ToolbarItem item) {
    items.add(item);
  }
  
  insert(ToolbarItem item, int position) {
    items.insert(position, item);
  }
  
  remove(int position) {
    items.remove(position);
  }
  
  List<ToolbarButton> get buttons {
    List<ToolbarButton> buttons = new List<ToolbarButton>();
    for (ToolbarItem item in items) {
      if (item is ToolbarBox)
        buttons.addAll(item.buttons);
    }
    return(buttons);
  }
  
  /**
   * Returns a list of all element references used in the toolbar.
   */
  List<x.Element> elementRefs() {
    if (cacheRefs != null)
      return(cacheRefs);
    List<x.Element> list = new List<x.Element>();
    for (ToolbarItem item in items) {
      if (item is ToolbarBox) {
        for (ToolbarButton button in item.buttons) {
          if (button.data is ToolbarStyleInfo) {
            ToolbarStyleInfo info = button.data;
            if (info.ref != null)
              list.add(info.ref);
          }
        }
      } else if (item is ToolbarMenu) {
        Menu menu = item.menu;
        for (MenuItem menuItem in menu.items) {
          if (menuItem.data is ToolbarStyleInfo) {
            ToolbarStyleInfo info = menuItem.data;
            if (info.ref != null)
              list.add(info.ref);
          }
        }
      }
    }
    cacheRefs = list;
    return(list);
  }
  
  h.Element html() {
    h.DivElement div = new h.DivElement();
    div.classes.add('toolbar');
    for (ToolbarItem item in items) {
      div.append(item.html());
    }
    return(div);
  }
  
  void update(DaxeNode parent, List<x.Element> validRefs) {
    List<x.Element> ancestorRefs = new List<x.Element>();
    for (DaxeNode n = parent; n != null; n = n.parent)
      ancestorRefs.add(n.ref);
    DaxeNode selectedNode = null;// will be !=null when the selection matches a full element
    Position start = page.getSelectionStart();
    Position end = page.getSelectionEnd();
    if (start.dn is! DNText && start.dn.offsetLength > start.dnOffset) {
      if (end == new Position(start.dn, start.dnOffset + 1))
        selectedNode = start.dn.childAtOffset(start.dnOffset);
    }
    // update buttons
    for (ToolbarButton button in buttons) {
      if (button.data is ToolbarStyleInfo) {
        ToolbarStyleInfo info = button.data;
        x.Element ref = info.ref;
        String css = info.css;
        if (ref == doc.hiddenp) {
          // paragraph style
          bool foundAncestor = false;
          for (DaxeNode n = parent; n != null; n = n.parent) {
            if (n.ref == doc.hiddenp && (n as DNHiddenP).css == css) {
              foundAncestor = true;
              break;
            }
          }
          if (foundAncestor) {
            button.enable();
            button.select();
          } else {
            if (selectedNode != null && doc.hiddenp == selectedNode.ref &&
                (selectedNode as DNHiddenP).css == css) {
              button.select();
            } else {
              button.deselect();
            }
            if (DNHiddenP.paragraphsInSelection().length > 0)
              button.enable();
            else
              button.disable();
          }
        } else if (doc.cfg.elementDisplayType(ref) == 'style') {
          // DNStyle, style with no css (as with the b element)
          if (ancestorRefs.contains(ref)) {
            button.enable();
            button.select();
          } else {
            if (selectedNode != null && ref == selectedNode.ref)
              button.select();
            else
              button.deselect();
            if (validRefs.contains(ref))
              button.enable();
            else
              button.disable();
          }
        } else if (doc.cfg.elementDisplayType(ref) == 'stylespan') {
          // DNSpanStyle, span style
          bool foundAncestor = false;
          for (DaxeNode n = parent; n != null; n = n.parent) {
            if (n.ref == ref && (n as DNStyleSpan).css == css) {
              foundAncestor = true;
              break;
            }
          }
          if (foundAncestor) {
            button.enable();
            button.select();
          } else {
            if (selectedNode != null && ref == selectedNode.ref &&
                (selectedNode as DNStyleSpan).css == css) {
              button.select();
            } else {
              button.deselect();
            }
            if (validRefs.contains(ref))
              button.enable();
            else
              button.disable();
          }
        } else if (ref == DNWList.ulRef() || ref == DNWList.olRef()) {
          // toggle list button
          bool foundAncestor = false;
          for (DaxeNode n = parent; n != null; n = n.parent) {
            if (n.ref == DNWList.ulRef() || n.ref == DNWList.olRef()) {
              foundAncestor = (n.ref == ref);
              break;
            }
          }
          if (foundAncestor) {
            button.enable();
            button.select();
          } else {
            button.deselect();
            if (validRefs.contains(ref))
              button.enable();
            else
              button.disable();
          }
        } else if (ref != null) {
          // element insert
          if (validRefs.contains(ref))
            button.enable();
          else
            button.disable();
        }
      } else if (button.data == 'rise_list_level') {
        Position start = page.getSelectionStart();
        DaxeNode dn = start.dn;
        while (dn != null && dn is! DNWItem)
          dn = dn.parent;
        if (dn != null)
          button.enable();
        else
          button.disable();
      } else if (button.data == 'lower_list_level') {
        Position start = page.getSelectionStart();
        DaxeNode dn = start.dn;
        while (dn != null && dn is! DNWItem)
          dn = dn.parent;
        if (dn == null || dn.previousSibling == null)
          button.disable();
        else
          button.enable();
      }
    }
    // update menus
    for (ToolbarItem tbitem in items) {
      if (tbitem is ToolbarMenu) {
        Menu menu = tbitem.menu;
        MenuItem selectedItem = null;
        for (MenuItem menuItem in menu.items) {
          if (menuItem.data is ToolbarStyleInfo) {
            ToolbarStyleInfo info = menuItem.data;
            x.Element ref = info.ref;
            String css = info.css;
            if (ref == doc.hiddenp) {
              // paragraph style
              bool foundAncestor = false;
              for (DaxeNode n = parent; n != null; n = n.parent) {
                if (n.ref == doc.hiddenp && (n as DNHiddenP).css == css) {
                  foundAncestor = true;
                  break;
                }
              }
              if (foundAncestor) {
                menuItem.enable();
                selectedItem = menuItem;
                menuItem.check();
              } else {
                if (selectedNode != null && doc.hiddenp == selectedNode.ref &&
                    (selectedNode as DNHiddenP).css == css) {
                  selectedItem = menuItem;
                  menuItem.check();
                } else {
                  menuItem.uncheck();
                }
                if (DNHiddenP.paragraphsInSelection().length > 0)
                  menuItem.enable();
                else
                  menuItem.disable();
              }
            } else if (doc.cfg.elementDisplayType(ref) == 'style') {
              // DNStyle
              if (ancestorRefs.contains(ref)) {
                menuItem.enable();
                selectedItem = menuItem;
              } else {
                if (selectedNode != null && ref == selectedNode.ref)
                  selectedItem = menuItem;
                if (validRefs.contains(ref))
                  menuItem.enable();
                else
                  menuItem.disable();
              }
            } else if (doc.cfg.elementDisplayType(ref) == 'stylespan') {
              // DNSpanStyle
              bool foundAncestor = false;
              for (DaxeNode n = parent; n != null; n = n.parent) {
                if (n.ref == ref && (n as DNStyleSpan).css == css) {
                  foundAncestor = true;
                  break;
                }
              }
              if (foundAncestor) {
                menuItem.enable();
                selectedItem = menuItem;
                menuItem.check();
              } else {
                if (selectedNode != null && ref == selectedNode.ref &&
                    (selectedNode as DNStyleSpan).css == css) {
                  selectedItem = menuItem;
                  menuItem.check();
                } else {
                  menuItem.uncheck();
                }
                if (validRefs.contains(ref))
                  menuItem.enable();
                else
                  menuItem.disable();
              }
            } else if (ref != null) {
              // element insert
              if (validRefs.contains(ref))
                menuItem.enable();
              else
                menuItem.disable();
            }
          }
        }
        if (selectedItem == null)
          menu.title = tbitem.title;
        else
          menu.title = selectedItem.title;
      }
    }
  }
  
}
