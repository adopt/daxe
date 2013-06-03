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
 * This class is useless, it does not return a real path on the disk.
 */
@deprecated
class FileOpenDialog {
  ActionFunction okfct;
  h.File file;
  
  FileOpenDialog(this.okfct) {
  }
  
  void show() {
    h.DivElement div1 = new h.DivElement();
    div1.id = 'dlg1';
    div1.classes.add('dlg1');
    h.DivElement div2 = new h.DivElement();
    div2.classes.add('dlg2');
    h.DivElement div3 = new h.DivElement();
    div3.classes.add('dlg3');
    h.FormElement form = new h.FormElement();
    
    h.FileUploadInputElement input = new h.FileUploadInputElement();
    input.id = 'file_input';
    input.onChange.listen((h.Event event) => onChange(event));
    form.append(input);
    
    h.DivElement div_buttons = new h.DivElement();
    div_buttons.classes.add('buttons');
    h.ButtonElement bCancel = new h.ButtonElement();
    bCancel.attributes['type'] = 'button';
    bCancel.appendText(Strings.get("button.Cancel"));
    bCancel.onClick.listen((h.MouseEvent event) => div1.remove());
    div_buttons.append(bCancel);
    h.ButtonElement bOk = new h.ButtonElement();
    bOk.id = 'file_ok';
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
  
  void onChange(h.Event event) {
    h.ButtonElement bOk = h.query('button#file_ok');
    bOk.disabled = false;
  }
  
  void ok(h.MouseEvent event) {
    event.preventDefault();
    h.FileUploadInputElement input = h.query('input#file_input');
    List<h.File> files = input.files;
    if (files.length > 0)
      file = files[0];
    h.query('div#dlg1').remove();
    okfct();
  }
  
  h.File getFile() {
    return(file);
  }
}
