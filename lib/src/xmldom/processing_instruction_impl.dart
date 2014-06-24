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

part of xmldom;

class ProcessingInstructionImpl extends NodeImpl implements ProcessingInstruction {
  String target;
  String data;
  
  ProcessingInstructionImpl.clone(final ProcessingInstruction pi) {
    target = pi.target;
    data = pi.data;
    
    nodeName = pi.nodeName;
    nodeValue = pi.nodeValue;
    nodeType = pi.nodeType;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = pi.ownerDocument;
    namespaceURI = pi.namespaceURI;
    prefix = null;
    localName = null;
  }
  
  ProcessingInstructionImpl(final Document doc, final String target, final String data) {
    this.target = target;
    this.data = data;
    
    nodeName = target;
    nodeValue = data;
    nodeType = Node.PROCESSING_INSTRUCTION_NODE;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = doc;
    namespaceURI = null;
    prefix = null;
    localName = null;
  }
  
  /*
  ProcessingInstructionImpl.fromDH(final Document doc, final h.ProcessingInstruction pi) {
    target = pi.target;
    data = pi.data;
    
    nodeName = target;
    nodeValue = pi.nodeValue;
    nodeType = Node.PROCESSING_INSTRUCTION_NODE;
    parentNode = null;
    childNodes = null;
    firstChild = null;
    lastChild = null;
    previousSibling = null;
    nextSibling = null;
    attributes = null;
    ownerDocument = doc;
    namespaceURI = null;
    prefix = null;
    localName = null;
  }
  */
  
  Node cloneNode(bool deep) {
    return(new ProcessingInstructionImpl.clone(this));
  }
  
  String toString() {
    return("<?$target $data?>");
  }
}

