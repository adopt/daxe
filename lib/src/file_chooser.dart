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

enum DirectoryItemType { FILE, DIRECTORY }

/**
 * Open dialog for the desktop application.
 * This assumes the server sends directory listings using the following syntax:
 * <directory name="current_dir">
 *   <file name="example.txt" size="10" modified="2015-08-07T13:49:59"/>
 *   <directory name="sub_dir"/>
 * </directory>
 * The file size is in bytes. The modified timestamp is using ISO-8601.
 */
class FileChooser {
  
  static final String iconPath = 'packages/daxe/images/file_chooser/';
  Uri uri;
  ActionFunction okfct;
  List<DirectoryItem> items;
  DirectoryItem selectedItem;
  h.TableRowElement selectedTR;
  
  FileChooser(this.uri, this.okfct);
  
  Future show() async {
    try {
      items = await readDirectory(uri);
    } on DaxeException catch (ex) {
      h.window.alert(ex.message);
      return;
    }
    
    selectedItem = null;
    selectedTR = null;
    h.DivElement div1 = new h.DivElement();
    div1.id = 'dlg1';
    div1.classes.add('dlg1');
    h.DivElement div2 = new h.DivElement();
    div2.classes.add('dlg2');
    h.DivElement div3 = new h.DivElement();
    div3.classes.add('dlg3');
    h.FormElement form = new h.FormElement();
    
    form.append(directoryDiv());
    
    h.DivElement div_buttons = new h.DivElement();
    div_buttons.classes.add('buttons');
    h.ButtonElement bCancel = new h.ButtonElement();
    bCancel.attributes['type'] = 'button';
    bCancel.appendText(Strings.get("button.Cancel"));
    bCancel.onClick.listen((h.MouseEvent event) => cancel());
    div_buttons.append(bCancel);
    h.ButtonElement bOk = new h.ButtonElement();
    bOk.id = 'open_ok';
    bOk.disabled = true;
    bOk.attributes['type'] = 'submit';
    bOk.appendText(Strings.get("button.OK"));
    bOk.onClick.listen((h.MouseEvent event) => ok(event));
    div_buttons.append(bOk);
    form.append(div_buttons);
    
    div3.append(form);
    div2.append(div3);
    div1.append(div2);
    h.document.body.append(div1);
  }
  
  h.DivElement directoryDiv() {
    h.DivElement dirDiv = new h.DivElement();
    dirDiv.id = 'open-dir-div';
    h.DivElement pathDiv = new h.DivElement();
    pathDiv.id = 'open-path-div';
    h.SpanElement span = new h.SpanElement();
    span.classes.add('open-path-segment');
    span.appendText('/');
    span.onClick.listen((h.MouseEvent e) {
      openDir(uri.replace(pathSegments:[]));
    });
    pathDiv.append(span);
    for (int i=0; i<uri.pathSegments.length; i++) {
      String segment = uri.pathSegments[i];
      List<String> subSegments = uri.pathSegments.sublist(0, i+1);
      span = new h.SpanElement();
      span.classes.add('open-path-segment');
      span.setAttribute('tabindex', '0');
      span.appendText(segment);
      span.onClick.listen((h.MouseEvent e) {
        openDir(uri.replace(pathSegments:subSegments));
      });
      span.onKeyDown.listen((h.KeyboardEvent event) {
        int keyCode = event.keyCode;
        if (keyCode == h.KeyCode.ENTER) {
          event.preventDefault();
          openDir(uri.replace(pathSegments:subSegments));
        }
      });
      pathDiv.append(span);
      pathDiv.appendText('/');
    }
    dirDiv.append(pathDiv);
    
    h.DivElement previewDiv = new h.DivElement();
    previewDiv.id = 'open-preview-div';
    dirDiv.append(previewDiv);
    
    h.DivElement tableDiv = new h.DivElement();
    tableDiv.id = 'open-table-div';
    h.TableElement table = new h.TableElement();
    table.id = 'open-table';
    table.classes.add('opendlg_table');
    h.TableRowElement tr = new h.TableRowElement();
    h.Element th = new h.Element.tag('th');
    tr.append(th);
    th = new h.Element.tag('th');
    th.text = Strings.get('open.name');
    tr.append(th);
    th = new h.Element.tag('th');
    th.text = Strings.get('open.size');
    tr.append(th);
    th = new h.Element.tag('th');
    th.text = Strings.get('open.modified');
    tr.append(th);
    table.append(tr);
    h.TableRowElement previousTr = null;
    DirectoryItem previousItem = null;
    for (DirectoryItem item in items) {
      h.TableRowElement tr = new h.TableRowElement();
      tr.setAttribute('tabindex', '-1');
      h.TableCellElement td = new h.TableCellElement();
      td.append(new h.ImageElement(src:iconPath+item.icon, width:16, height:16));
      tr.append(td);
      td = new h.TableCellElement();
      td.text = item.name;
      tr.append(td);
      td = new h.TableCellElement();
      if (item.size != null) {
        String ssize;
        if (item.size > 1000000)
          ssize = (item.size / 1000000).round().toString() + ' MB';
        else if (item.size > 1000)
          ssize = (item.size / 1000).round().toString() + ' kB';
        else
          ssize = item.size.toString() + ' B';
        td.text = ssize;
      }
      tr.append(td);
      td = new h.TableCellElement();
      if (item.modified != null) {
        // NOTE: I tried to use Dart's DateFormat,
        // but it was excessively complicated to setup and required
        // the whole data folder from the intl package.
        DateTime date = item.modified.toLocal();
        String s;
        // this is of course incomplete
        if (Strings.systemLocale != null && Strings.systemLocale.endsWith('US'))
          s = "${date.month}/${date.day}/${date.year} ";
        else if (Strings.systemLocale != null && (Strings.systemLocale.endsWith('CN') ||
            Strings.systemLocale.endsWith('JP')))
          s = "${date.year}/${date.month}/${date.day} ";
        else
          s = "${date.day}/${date.month}/${date.year} ";
        s += "${date.hour}:${date.minute}:${date.second}";
        td.text = s;
      }
      tr.append(td);
      tr.onClick.listen((h.MouseEvent event) {
        event.preventDefault();
        select(item, tr);
      });
      tr.onDoubleClick.listen((h.MouseEvent event) => open(item));
      {
        DirectoryItem pi = previousItem;
        h.TableRowElement pt = previousTr;
        tr.onKeyDown.listen((h.KeyboardEvent event) {
          int keyCode = event.keyCode;
          if (keyCode == h.KeyCode.ENTER) {
            event.preventDefault();
            open(item);
          } else if (pi != null && keyCode == h.KeyCode.UP) {
            event.preventDefault();
            select(pi, pt);
          }
        });
      }
      if (previousItem != null) {
        previousTr.onKeyDown.listen((h.KeyboardEvent event) {
          int keyCode = event.keyCode;
          if (keyCode == h.KeyCode.DOWN) {
            event.preventDefault();
            select(item, tr);
          }
        });
      }
      table.append(tr);
      previousItem = item;
      previousTr = tr;
    }
    tableDiv.append(table);
    dirDiv.append(tableDiv);
    return dirDiv;
  }
  
  static Future<List<DirectoryItem>> readDirectory(Uri uri) async {
    List<DirectoryItem> items = new List<DirectoryItem>();
    x.DOMParser dp = new x.DOMParser();
    try {
      String suri = uri.toString();
      if (!suri.endsWith('/'))
        suri = suri + '/';
      x.Document xmldoc = await dp.parseFromURL(suri, disableCache:false);
      x.Element root = xmldoc.documentElement;
      if (root == null || root.nodeName != 'directory') {
        throw new DaxeException(Strings.get('open.error') + ': <${root.nodeName}>');
      }
      for (x.Node n=root.firstChild; n != null; n=n.nextSibling) {
        if (n is x.Element) {
          DirectoryItemType type;
          if (n.nodeName == 'directory')
            type = DirectoryItemType.DIRECTORY;
          else if (n.nodeName == 'file')
            type = DirectoryItemType.FILE;
          else
            continue;
          String name;
          if (n.getAttribute('name') != '')
            name = n.getAttribute('name');
          int size;
          if (n.getAttribute('size') != '')
            size = int.parse(n.getAttribute('size'));
          DateTime modified;
          if (n.getAttribute('modified') != '')
            modified = DateTime.parse(n.getAttribute('modified'));
          items.add(new DirectoryItem(type, name, size, modified));
        }
      }
      items.sort((DirectoryItem item1, DirectoryItem item2) {
        return(item1.name.compareTo(item2.name));
      });
    } on x.DOMException catch (ex) {
      throw new DaxeException(Strings.get('open.error'), ex);
    }
    return items;
  }
  
  void select(DirectoryItem item, h.TableRowElement tr) {
    if (selectedTR != null)
      selectedTR.classes.remove('selected');
    tr.classes.add('selected');
    selectedTR = tr;
    selectedItem = item;
    h.ButtonElement bOk = h.querySelector('button#open_ok');
    bOk.disabled = false;
    h.DivElement previewDiv = h.document.getElementById('open-preview-div');
    previewDiv.children.clear();
    if (item.icon == 'image_file.png') {
      h.ImageElement img = new h.ImageElement();
      img.src = uri.path + '/' + item.name;
      previewDiv.append(img);
    }
    tr.focus();
  }
  
  Uri itemUri(DirectoryItem item) {
    List<String> segments = new List<String>.from(uri.pathSegments);
    segments.add(item.name);
    return(uri.replace(pathSegments:segments));
  }
  
  void open(DirectoryItem item) {
    if (item.type == DirectoryItemType.DIRECTORY) {
      Uri uri = itemUri(item);
      openDir(uri);
    } else
      closeAndLaunchOpenAction();
  }
  
  void closeAndLaunchOpenAction() {
    h.querySelector('div#dlg1').remove();
    if (okfct != null)
      okfct();
  }
  
  Future openDir(Uri uri) async {
    try {
      items = await readDirectory(uri);
    } on DaxeException catch (ex) {
      h.window.alert(ex.toString());
      return;
    }
    this.uri = uri;
    h.DivElement dirDiv = h.document.getElementById('open-dir-div');
    dirDiv.replaceWith(directoryDiv());
  }
  
  void ok(h.MouseEvent event) {
    if (event != null)
      event.preventDefault();
    if (selectedItem == null)
      return;
    open(selectedItem);
  }
  
  void cancel() {
    h.querySelector('div#dlg1').remove();
    page.focusCursor();
  }
  
  Uri getSelectedUri() {
    return(itemUri(selectedItem));
  }
}

class DirectoryItem {
  DirectoryItemType type;
  String name;
  int size;
  DateTime modified;
  DirectoryItem(this.type, this.name, [this.size, this.modified]);
  
  String get icon {
    if (name == null)
      return 'generic_file.png';
    String icon;
    String lcname = name.toLowerCase();
    if (type == DirectoryItemType.DIRECTORY)
      icon = 'folder.png';
    else if (lcname.endsWith('.xml') || lcname.endsWith('.problem') ||
        lcname.endsWith('.exam') || lcname.endsWith('.survey'))
      icon = 'xml_file.png';
    else if (lcname.endsWith('.gif') || lcname.endsWith('.jpg') ||
        lcname.endsWith('.jpeg') || lcname.endsWith('.png') ||
        lcname.endsWith('.svg'))
      icon = 'image_file.png';
    else if (lcname.endsWith('.html') || lcname.endsWith('.htm'))
      icon = 'html_file.png';
    else
      icon = 'generic_file.png';
    return icon;
  }
}
