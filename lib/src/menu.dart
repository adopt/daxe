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

class Menu extends MenuItem {
  List<MenuItem> items;
  String menuid;
  
  Menu(String title) : super(title, null) {
    items = new List<MenuItem>();
    this.menuid = "menu_${MenuItem.itemidcount-1}";
  }
  
  add(MenuItem item) {
    item.parent = this;
    items.add(item);
  }
  
  @override
  h.Element htmlItem() {
    h.TableRowElement tr = new h.TableRowElement();
    tr.id = itemid;
    tr.setAttribute('tabindex', '-1');
    tr.onKeyDown.listen((h.KeyboardEvent event) {
      if (h.document.activeElement != tr)
        return; // an item could have the focus, and the onKeyDown will trigger
      int keyCode = event.keyCode;
      if (keyCode == h.KeyCode.ENTER) {
        select();
      } else if (keyCode == h.KeyCode.UP) {
        (parent as Menu).selectPrevious(this);
      } else if (keyCode == h.KeyCode.DOWN) {
        (parent as Menu).selectNext(this);
      } else if (keyCode == h.KeyCode.LEFT) {
        if (parent is Menu) {
          if ((parent as Menu).parent is Menu)
            (parent as Menu).select();
          else if ((parent as Menu).parent is MenuBar)
            ((parent as Menu).parent as MenuBar).selectPrevious(parent as Menu);
        }
      } else if (keyCode == h.KeyCode.RIGHT) {
        for (MenuItem item in items) {
          if (item.enabled) {
            item.select();
            break;
          }
        }
      } else if (keyCode == h.KeyCode.TAB) {
        Timer.run(closeMenu);
      }
    });
    h.TableCellElement td = new h.TableCellElement();
    td.text = _title;
    td.onMouseOver.listen((h.MouseEvent event) {
      if (enabled) {
        select();
        show();
      }
    });
    tr.append(td);
    td = new h.TableCellElement();
    td.text = ">";
    h.DivElement divSubMenu = htmlMenu();
    divSubMenu.classes.remove('dropdown_menu');
    divSubMenu.classes.add('submenu');
    divSubMenu.style.display = 'none';
    td.append(divSubMenu);
    td.onMouseOver.listen((h.MouseEvent event) {
      if (enabled) {
        select();
        show();
      }
    });
    tr.append(td);
    if (!enabled)
      tr.classes.add('disabled');
    if (toolTipText != null)
      tr.title = toolTipText;
    return(tr);
  }
  
  h.Element htmlMenu() {
    h.DivElement div = new h.DivElement();
    div.classes.add('dropdown_menu');
    div.id = menuid;
    h.TableElement table = new h.TableElement();
    table.classes.add('menu');
    for (MenuItem item in items) {
      table.append(item.htmlItem());
    }
    div.append(table);
    return(div);
  }
  
  h.Element getMenuHTMLNode() {
    return(h.querySelector("#$menuid"));
  }
  
  void show() {
    h.DivElement div = getMenuHTMLNode();
    div.style.display = 'block';
    //h.SpanElement spanTitle = h.query("#menutitle_$id");
    // to avoid setting coordinates, we use a div with position absolute
    // and top 100% inside a div with position relative...
    //int top = spanTitle.offsetTop + spanTitle.offsetHeight;
    //int left = spanTitle.offsetLeft;
    //hMenu.style.top = "${top}px";
    //hMenu.style.left = "${left}px";
  }
  
  void hide() {
    for (MenuItem item in items) {
      if (item is Menu)
        item.hide();
      item.deselect();
    }
    h.DivElement div = getMenuHTMLNode();
    div.style.display = 'none';
  }
  
  bool isVisible() {
    h.DivElement div = getMenuHTMLNode();
    return(div.style.display != 'none');
  }
  
  void addSeparator() {
    items.add(new MenuItem.separator());
  }
  
  void deselectOtherItems(MenuItem menuitem) {
    for (MenuItem item in items) {
      if (item != menuitem)
        item.deselect();
    }
  }
  
  void set title(String title) {
    _title = title;
    h.Element hel = h.querySelector("#$itemid");
    if (hel is h.TableRowElement) {
      h.TableRowElement tr = hel;
      h.TableCellElement td = tr.nodes.first;
      td.text = title;
    } else if (hel is h.DivElement) {
      h.Node firstNode = hel.firstChild;
      if (firstNode is h.Text)
        firstNode.text = title;
    }
  }
  
  void checkEnabled() {
    bool en = false;
    for (MenuItem item in items) {
      if (item.enabled) {
        en = true;
        break;
      }
    }
    if (en == enabled)
      return;
    h.Element el = h.querySelector("#$itemid");
    if (en)
      el.classes.remove('disabled');
    else
      el.classes.add('disabled');
    enabled = en;
    if (parent is Menu)
      (parent as Menu).checkEnabled();
  }
  
  /*
  @override
  void close() {
    if (parent != null)
      parent.close();
    else
      hide();
  }
  */
  
  void selectFirst() {
    for (MenuItem item in items) {
      if (item.enabled) {
        item.select();
        return;
      }
    }
  }
  
  void selectPrevious(MenuItem current) {
    bool found = false;
    for (MenuItem item in items.reversed) {
      if (item == current) {
        found = true;
      } else if (found && item.enabled) {
        current.deselect();
        item.select();
        break;
      }
    }
  }
  
  void selectNext(MenuItem current) {
    bool found = false;
    for (MenuItem item in items) {
      if (item == current) {
        found = true;
      } else if (found && item.enabled) {
        current.deselect();
        item.select();
        break;
      }
    }
  }
  
}
