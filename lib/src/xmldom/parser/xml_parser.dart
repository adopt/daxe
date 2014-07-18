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

/**
 * DOM XML parser.
 * It is not feature-complete, and does not report errors well for documents that are not well-formed.
 */
class XMLParser {
  
  // The implementation was inspired by http://www.antlr.org/wiki/display/ANTLR3/Parsing+XML
  
  List<TokenRule> lexRules;
  List<TokenRule> xmlRules;
  Document doc;
  
  XMLParser() {
    _initRules();
  }
  
  _initRules() {
    lexRules = new List<TokenRule>();
    StateCondition inTag = new StateCondition('in_tag', true);
    lexRules.add(new TokenRule('CDATA_SECTION_OPEN', new TokenSequence.string('<![CDATA['),
        conditions: [new StateCondition('in_cdata_section', false)],
        changes: [new StateChange('in_cdata_section', true)]));
    lexRules.add(new TokenRule('CDATA_SECTION_DATA', new TokenRepeat.oneOrMore(new TokenChar.except([']]>'])),
        conditions: [new StateCondition('in_cdata_section', true)]));
    lexRules.add(new TokenRule('CDATA_SECTION_CLOSE', new TokenSequence.string(']]>'),
        conditions: [new StateCondition('in_cdata_section', true)],
        changes: [new StateChange('in_cdata_section', false)]));
    lexRules.add(new TokenRule('COMMENT_OPEN', new TokenSequence.string('<!--'),
        changes: [new StateChange('in_comment', true)]));
    lexRules.add(new TokenRule('COMMENT_CLOSE', new TokenSequence.string('-->'),
        conditions: [new StateCondition('in_comment', true)],
        changes: [new StateChange('in_comment', false)]));
    lexRules.add(new TokenRule('COMMENT_DATA', new TokenRepeat.oneOrMore(new TokenChar.except(['-->'])),
        conditions: [new StateCondition('in_comment', true)]));
    lexRules.add(new TokenRule('DOC_DECL_OPEN', new TokenSequence.string('<?xml'),
        changes: [new StateChange('in_tag', true), new StateChange('in_decl', true)]));
    lexRules.add(new TokenRule('DOC_DECL_CLOSE', new TokenSequence.string('?>'),
        conditions: [new StateCondition('in_decl', true)],
        changes: [new StateChange('in_tag', false), new StateChange('in_decl', false)]));
    lexRules.add(new TokenRule('DOCTYPE_OPEN', new TokenSequence.string('<!DOCTYPE'),
        changes: [new StateChange('in_tag', true), new StateChange('in_doctype', true)]));
    lexRules.add(new TokenRule('DOCTYPE_CLOSE', new TokenSequence.string('>'),
        conditions: [new StateCondition('in_doctype', true)],
        changes: [new StateChange('in_tag', false), new StateChange('in_doctype', false)]));
    lexRules.add(new TokenRule('PI_OPEN', new TokenSequence.string('<?'),
        changes: [new StateChange('in_pi', true)]));
    TokenItem firstChar = new TokenChoice([
      new TokenChar.letter(),
      new TokenChar('_'),
      new TokenChar(':')
    ]);
    TokenItem nameChar = new TokenChoice([
      new TokenChar.letter(),
      new TokenChar.digit(),
      new TokenChar('.'),
      new TokenChar('-'),
      new TokenChar('_'),
      new TokenChar(':')
    ]);
    lexRules.add(new TokenRule('PI_TARGET', new TokenSequence([
        firstChar,
        new TokenRepeat.zeroOrMore(nameChar)
        ]),
        conditions: [new StateCondition('in_pi', true), new StateCondition('pi_after_target', false)],
        changes: [new StateChange('pi_after_target', true)]));
    lexRules.add(new TokenRule('PI_DATA', new TokenRepeat.oneOrMore(new TokenChar.except(['?>'])),
        conditions: [new StateCondition('pi_after_target', true)]));
    lexRules.add(new TokenRule('PI_CLOSE', new TokenSequence.string('?>'),
        conditions: [new StateCondition('in_pi', true)],
        changes: [new StateChange('in_pi', false), new StateChange('pi_after_target', false)]));
    lexRules.add(new TokenRule('TAG_END_OPEN', new TokenSequence.string('</'),
        changes: [new StateChange('in_tag', true)]));
    lexRules.add(new TokenRule('TAG_START_OPEN', new TokenChar('<'),
        changes: [new StateChange('in_tag', true)]));
    lexRules.add(new TokenRule('TAG_CLOSE', new TokenChar('>'),
        conditions: [inTag],
        changes: [new StateChange('in_tag', false)]));
    lexRules.add(new TokenRule('TAG_EMPTY_CLOSE', new TokenSequence.string('/>'),
        conditions: [inTag],
        changes: [new StateChange('in_tag', false)]));
    lexRules.add(new TokenRule('ATTR_EQ', new TokenChar('='),
        conditions: [inTag]));
    TokenRule entityRef = new TokenRule('ENTITY_REF', new TokenSequence([
      new TokenChar('&'),
      new TokenRepeat.oneOrMore(
        new TokenChoice([
          new TokenChar('#'),
          new TokenChar.digit(),
          new TokenChar.letter()
        ])
      ),
      new TokenChar(';')
    ]), action: (Token token) {
      String data = token.matchedString;
      data = data.substring(1, data.length - 1);
      if (data.startsWith('#')) {
        int num;
        if (data[1] == 'x') {
          data = data.substring(2);
          num = int.parse(data, radix: 16);
        } else {
          data = data.substring(1);
          num = int.parse(data);
        }
        String s = new String.fromCharCode(num);
        token.matchedString = new String.fromCharCode(num);
      } else {
        String s = null;
        if (data == 'amp')
          s = '&';
        else if (data == 'lt')
          s = '<';
        else if (data == 'gt')
          s = '>';
        else if (data == 'apos')
          s = "'";
        else if (data == 'quot')
          s = '"';
        if (s != null) {
          token.matchedString = s;
        } else {
          // unknown named entity: we can't replace it here
        }
      }
    });
    lexRules.add(entityRef);
    lexRules.add(new TokenRule('ATTR_VALUE', new TokenChoice([
        new TokenSequence([
          new TokenChar('"'),
          new TokenRepeat.zeroOrMore(
            new TokenChoice([
              new TokenChar.except(['"', '&', '<']),
              entityRef
            ])
          ),
          new TokenChar('"')
        ]),
        new TokenSequence([
          new TokenChar("'"),
          new TokenRepeat.zeroOrMore(
            new TokenChoice([
              new TokenChar.except(["'", '&', '<']),
              entityRef
            ])
          ),
          new TokenChar("'")
        ])
      ]),
      conditions: [inTag]));
    lexRules.add(new TokenRule('PCDATA', new TokenRepeat.oneOrMore(new TokenChar.except(['<', '&'])),
        conditions: [new StateCondition('in_tag', false)]));
    lexRules.add(new TokenRule('GENERIC_ID', new TokenSequence([
        firstChar,
        new TokenRepeat.zeroOrMore(nameChar)
      ]),
      conditions: [inTag]));
    lexRules.add(new TokenRule('WHITE', new TokenChoice([
        new TokenChar(' '),
        new TokenChar('\n'),
        new TokenChar('\r'),
        new TokenChar('\t')
      ]),
      conditions: [inTag],
      ignore: true));
    
    
    xmlRules = new List<TokenRule>();
    TokenRule attributeRule = new TokenRule('ATTRIBUTE', new TokenSequence([
        new TokenId('GENERIC_ID'),
        new TokenId('ATTR_EQ'),
        new TokenId('ATTR_VALUE')
      ]), action: (Token token) {
        String name = token.matchedTokens[0].matchedString;
        String value = token.matchedTokens[2].matchedString;
        value = value.substring(1, value.length - 1);
        Attr attr = new AttrImpl.NS(doc, null, name);
        attr.value = value;
        token.data = attr;
      }
    );
    xmlRules.add(new TokenRule('DOC_DECL', new TokenSequence([
      new TokenId('DOC_DECL_OPEN'),
      new TokenRepeat.zeroOrMore(attributeRule),
      new TokenId('DOC_DECL_CLOSE')
    ]), action: (Token token) {
      int nbAttributes = token.matchedTokens.length - 2;
      if (nbAttributes > 0) {
        for (int i= 1; i < token.matchedTokens.length - 1; i++) {
          Object data = token.matchedTokens[i].data;
          if (data is Attr) {
            Attr attr = data;
            if (attr.name == 'version')
              doc.xmlVersion = attr.value;
            else if (attr.name == 'encoding') {
             doc.xmlEncoding = attr.value;
             doc.inputEncoding = attr.value;
            }
          }
        }
      }
    }));
    xmlRules.add(new TokenRule('DOCTYPE', new TokenSequence([
      new TokenId('DOCTYPE_OPEN'),
      new TokenRepeat.oneOrMore(
        new TokenChoice([
          new TokenId('GENERIC_ID'),
          new TokenId('ATTR_VALUE')
        ])
      ),
      new TokenId('DOCTYPE_CLOSE')
    ]), action: (Token token) {
      String name = token.matchedTokens[1].matchedString;
      String publicId = null;
      String systemId = null;
      for (int i=2; i<token.matchedTokens.length - 1; i++) {
        if (token.matchedTokens[i].id == 'GENERIC_ID' &&
            token.matchedTokens[i].matchedString == 'PUBLIC' &&
            i < token.matchedTokens.length - 2 &&
            token.matchedTokens[i+1].id == 'ATTR_VALUE') {
          publicId = token.matchedTokens[i+1].matchedString;
          publicId = publicId.substring(1, systemId.length - 1);
        } else if (token.matchedTokens[i].id == 'GENERIC_ID' &&
            token.matchedTokens[i].matchedString == 'SYSTEM' &&
            i < token.matchedTokens.length - 2 &&
            token.matchedTokens[i+1].id == 'ATTR_VALUE') {
          systemId = token.matchedTokens[i+1].matchedString;
          systemId = systemId.substring(1, systemId.length - 1);
        }
        // TODO: better support for DOCTYPE
      }
      DocumentType doctype = new DocumentTypeImpl(name, publicId, systemId);
      doctype.ownerDocument = doc;
      token.data = doctype;
    }));
    xmlRules.add(new TokenRule('OUTSIDE_ROOT', new TokenId('PCDATA'),
        ignore: true));
    TokenRule startTagRule = new TokenRule('START_TAG', new TokenSequence([
      new TokenId('TAG_START_OPEN'),
      new TokenId('GENERIC_ID'),
      new TokenRepeat.zeroOrMore(attributeRule),
      new TokenId('TAG_CLOSE')
    ]));
    TokenRule endTagRule = new TokenRule('END_TAG', new TokenSequence([
      new TokenId('TAG_END_OPEN'),
      new TokenId('GENERIC_ID'),
      new TokenId('TAG_CLOSE')
    ]));
    TokenRule emptyElementRule = new TokenRule('EMPTY_ELEMENT', new TokenSequence([
      new TokenId('TAG_START_OPEN'),
      new TokenId('GENERIC_ID'),
      new TokenRepeat.zeroOrMore(attributeRule),
      new TokenId('TAG_EMPTY_CLOSE')
    ]));
    TokenRule commentRule = new TokenRule('COMMENT', new TokenSequence([
      new TokenId('COMMENT_OPEN'),
      new TokenRepeat.zeroOrOne(new TokenId('COMMENT_DATA')),
      new TokenId('COMMENT_CLOSE')
    ]), action: (Token token) {
      String data;
      if (token.matchedTokens.length == 3)
        data = token.matchedTokens[1].matchedString;
      else
        data = '';
      token.data = new CommentImpl(doc, data);
    });
    TokenRule entityRefRule = new TokenRule('ENTITY_REF', new TokenSequence([
      new TokenId('ENTITY_REF')
    ]), action: (Token token) {
      String data = token.matchedTokens[0].matchedString;
      if (data.startsWith('&') && data.length > 1) {
        data = data.substring(1, data.length - 1);
        EntityReferenceImpl entityRef = new EntityReferenceImpl(doc, data);
        token.data = entityRef;
      } else {
        token.data = new TextImpl(doc, data);
      }
    });
    TokenRule cdataSectionRule = new TokenRule('CDATA', new TokenSequence([
      new TokenId('CDATA_SECTION_OPEN'),
      new TokenRepeat.zeroOrOne(new TokenId('CDATA_SECTION_DATA')),
      new TokenId('CDATA_SECTION_CLOSE')
    ]), action: (Token token) {
      String data;
      if (token.matchedTokens.length == 3)
        data = token.matchedTokens[1].matchedString;
      else
        data = '';
      token.data = new CDATASectionImpl(doc, data);
    });
    TokenRule piRule = new TokenRule('PI', new TokenSequence([
      new TokenId('PI_OPEN'),
      new TokenId('PI_TARGET'),
      new TokenRepeat.zeroOrOne(new TokenId('PI_DATA')),
      new TokenId('PI_CLOSE')
    ]), action: (Token token) {
      String target = token.matchedTokens[1].matchedString;
      String data;
      if (token.matchedTokens.length == 4)
        data = token.matchedTokens[2].matchedString.replaceAll(new RegExp(r"^\s+"), '');
      else
        data = '';
      token.data = new ProcessingInstructionImpl(doc, target, data);
    });
    TokenRule elementRule = new TokenRule('ELEMENT', null, action: (Token token) {
      bool empty = (token.matchedTokens[0].id == 'EMPTY_ELEMENT');
      Token startTagToken = token.matchedTokens[0];
      String name = startTagToken.matchedTokens[1].matchedString;
      if (!empty) {
        // check that the end tag matches the start tag
        // (this could be disabled for speed, assuming documents are well-formed)
        Token endTagToken = token.matchedTokens[token.matchedTokens.length - 1];
        String endName = endTagToken.matchedTokens[1].matchedString;
        if (endName != name)
          throw new Exception("End tag not matching start tag: $endName != $name");
      }
      Element el = new ElementImpl.NS(doc, null, name);
      int nbAttributes = startTagToken.matchedTokens.length - 3;
      if (nbAttributes > 0) {
        for (int i= 2; i < startTagToken.matchedTokens.length - 1; i++) {
          Object data = startTagToken.matchedTokens[i].data;
          if (data is Attr)
            el.setAttributeNode(data);
        }
      }
      if (!empty) {
        int nbChildren = token.matchedTokens.length - 2;
        if (nbChildren > 0) {
          for (int i= 1; i < token.matchedTokens.length - 1; i++) {
            Token tokeni = token.matchedTokens[i]; 
            if (tokeni.id == 'PCDATA') {
              Text text = new TextImpl(doc, tokeni.matchedString);
              el.appendChild(text);
            } else {
              Object data = tokeni.data;
              if (data is Node)
                el.appendChild(data);
            }
          }
          // normalize text nodes (but not CDATA sections)
          for (Node n = el.firstChild; n != null; n = n.nextSibling) {
            if (n.nodeType == Node.TEXT_NODE) {
              Node n2 = n.nextSibling;
              while (n2 != null && n2.nodeType == Node.TEXT_NODE) {
                n.nodeValue += n2.nodeValue;
                el.removeChild(n2);
                n2 = n.nextSibling;
              }
            }
          }
        }
      }
      token.data = el;
    });
    elementRule.content = new TokenChoice([
      new TokenSequence([
        startTagRule,
        new TokenRepeat.zeroOrMore(
          new TokenChoice([
            elementRule,
            commentRule,
            new TokenId('PCDATA'),
            entityRefRule,
            cdataSectionRule,
            piRule
          ])
        ),
        endTagRule
      ]),
      emptyElementRule
    ]);
    xmlRules.add(elementRule);
    // we need to add these rules so that they get associated with the engine:
    xmlRules.add(attributeRule);
    xmlRules.add(startTagRule);
    xmlRules.add(endTagRule);
    xmlRules.add(emptyElementRule);
    xmlRules.add(commentRule);
    xmlRules.add(entityRefRule);
    xmlRules.add(cdataSectionRule);
    xmlRules.add(piRule);
  }
  
  Document parseString(String s) {
    s = s.replaceAll('\r\n', '\n');
    DOMImplementation implementation = new DOMImplementationImpl();
    doc = new DocumentImpl(implementation, null, null, null);
    
    Engine engine = new Engine(lexRules);
    List<Token> tokens = engine.parseString(s);
    
    engine = new Engine(xmlRules);
    tokens = engine.parseTokens(tokens);
    for (Token token in tokens) {
      Object data = token.data;
      if (data is DocumentType)
        doc.doctype = data;
      else if (data is Node)
        doc.appendChild(data);
    }
    if (doc.documentElement != null)
      _fixNamespaces(doc.documentElement);
    return(doc);
  }
  
  void _fixNamespaces(Element el) {
    if (el.attributes != null) {
      for (Attr attr in el.attributes.values) {
        if (attr.name == 'xmlns' ||
            (attr.prefix == 'xmlns' && attr.localName == el.prefix)) {
          el.namespaceURI = attr.value;
          break;
        }
      }
    }
    if (el.namespaceURI == null && el.parentNode != null)
      el.namespaceURI = el.parentNode.lookupNamespaceURI(el.prefix);
    for (Node n = el.firstChild; n != null; n = n.nextSibling) {
      if (n is Element)
        _fixNamespaces(n as Element);
    }
  }
}
