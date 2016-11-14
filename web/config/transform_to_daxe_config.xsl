<?xml version='1.0' encoding='UTF-8'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

<xsl:template match="CONFIG_JAXE">
    <DAXE_CONFIG>
        <xsl:apply-templates/>
    </DAXE_CONFIG>
</xsl:template>

<xsl:template match="LANGAGE">
    <LANGUAGE>
        <xsl:apply-templates/>
    </LANGUAGE>
</xsl:template>

<xsl:template match="FICHIER_SCHEMA">
    <SCHEMA_FILE name="{@nom}"/>
</xsl:template>

<xsl:template match="SCHEMA_SIMPLE">
    <SIMPLE_SCHEMA>
        <xsl:apply-templates/>
    </SIMPLE_SCHEMA>
</xsl:template>

<xsl:template match="ELEMENT">
    <ELEMENT name="{@nom}">
        <xsl:if test="@texte">
            <xsl:attribute name="text">
                <xsl:choose>
                    <xsl:when test="@texte='autorise'">allowed</xsl:when>
                    <xsl:otherwise>prohibited</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
    </ELEMENT>
</xsl:template>

<xsl:template match="SOUS-ELEMENT">
    <CHILD-ELEMENT element="{@element}"/>
</xsl:template>

<xsl:template match="SOUS-ENSEMBLE">
    <CHILD-SET set="{@ensemble}"/>
</xsl:template>

<xsl:template match="ATTRIBUT">
    <ATTRIBUTE name="{@nom}">
        <xsl:attribute name="text">
            <xsl:choose>
                <xsl:when test="@presence='obligatoire'">required</xsl:when>
                <xsl:otherwise>optional</xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates/>
    </ATTRIBUTE>
</xsl:template>

<xsl:template match="VALEUR">
    <VALUE><xsl:apply-templates/></VALUE>
</xsl:template>

<xsl:template match="ENSEMBLE">
    <SET name="{@nom}">
        <xsl:apply-templates/>
    </SET>
</xsl:template>

<xsl:template match="RACINE">
    <ROOT element="{@element}"/>
</xsl:template>

<xsl:template match="AUTRE_CONFIG"></xsl:template>

<xsl:template match="ENREGISTREMENT">
    <SAVING>
        <xsl:apply-templates/>
    </SAVING>
</xsl:template>

<xsl:template match="ENCODAGE">
    <ENCODING><xsl:apply-templates/></ENCODING>
</xsl:template>

<xsl:template match="DOCTYPE">
    <DOCTYPE>
        <xsl:apply-templates select="@*"/>
    </DOCTYPE>
</xsl:template>

<xsl:template match="SCHEMALOCATION">
    <SCHEMALOCATION>
        <xsl:apply-templates select="@*"/>
    </SCHEMALOCATION>
</xsl:template>

<xsl:template match="PREFIXE_ESPACE">
    <NAMESPACE_PREFIX prefix="{@prefixe}" uri="{@uri}"/>
</xsl:template>

<xsl:template match="MENUS">
    <MENUS>
        <xsl:apply-templates/>
    </MENUS>
</xsl:template>

<xsl:template match="MENU">
    <MENU name="{@nom}">
        <xsl:apply-templates/>
    </MENU>
</xsl:template>

<xsl:template match="MENU_INSERTION">
    <INSERT_MENU name="{@nom}">
        <xsl:if test="@type_noeud">
            <xsl:attribute name="node_type">
                <xsl:choose>
                    <xsl:when test="@type_noeud='instruction'">pi</xsl:when>
                    <xsl:when test="@type_noeud='commentaire'">comment</xsl:when>
                    <xsl:otherwise><xsl:value-of select="@type_noeud"/></xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="@raccourci">
            <xsl:attribute name="shortcut">
                <xsl:value-of select="@raccourci"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
    </INSERT_MENU>
</xsl:template>

<xsl:template match="MENU_FONCTION">
    <FUNCTION_MENU name="{@nom}" function_name="{@classe}">
        <xsl:if test="@raccourci">
            <xsl:attribute name="shortcut">
                <xsl:value-of select="@raccourci"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
    </FUNCTION_MENU>
</xsl:template>

<xsl:template match="PARAMETRE">
    <xsl:if test="not(../@type='plugin' and @nom='classe')">
        <PARAMETER>
            <xsl:attribute name="name">
                <xsl:choose>
                    <xsl:when test="@nom='attributsVisibles'">visibleAttributes</xsl:when>
                    <xsl:when test="@nom='titreAtt'">titleAtt</xsl:when>
                    <xsl:when test="@nom='typeListe'">listType</xsl:when>
                    <xsl:when test="@nom='texteAtt'">textAtt</xsl:when>
                    <xsl:when test="@nom='police'">font</xsl:when>
                    <xsl:when test="@nom='taille'">size</xsl:when>
                    <xsl:when test="@nom='serveur'">server</xsl:when>
                    <xsl:otherwise><xsl:value-of select="@nom"/></xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:attribute name="value">
                <xsl:choose>
                    <xsl:when test="@nom='style'">
                        <xsl:call-template name="translate-style">
                            <xsl:with-param name="style" select="@valeur"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise><xsl:value-of select="@valeur"/></xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </PARAMETER>
    </xsl:if>
</xsl:template>

<xsl:template name="translate-style">
    <xsl:param name="style"/>
    <xsl:variable name="first">
        <xsl:choose>
            <xsl:when test="contains($style, ';')">
                <xsl:value-of select="substring-before($style, ';')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$style"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$first='GRAS'">BOLD</xsl:when>
        <xsl:when test="$first='ITALIQUE'">ITALIC</xsl:when>
        <xsl:when test="$first='EXPOSANT'">SUPERSCRIPT</xsl:when>
        <xsl:when test="$first='INDICE'">SUBSCRIPT</xsl:when>
        <xsl:when test="$first='SOULIGNE'">UNDERLINE</xsl:when>
        <xsl:when test="$first='BARRE'">STRIKETHROUGH</xsl:when>
        <xsl:when test="contains($first,'FCOULEUR')">BACKGROUND[<xsl:value-of select="substring-after($first, '[')"/></xsl:when>
        <xsl:when test="contains($first,'PCOULEUR')">FOREGROUND[<xsl:value-of select="substring-after($first, '[')"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$first"/></xsl:otherwise>
    </xsl:choose>
    <xsl:if test="contains($style, ';')">
        <xsl:text>;</xsl:text>
        <xsl:call-template name="translate-style">
            <xsl:with-param name="style" select="substring-after($style, ';')"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template match="SEPARATEUR">
    <SEPARATOR/>
</xsl:template>

<xsl:template match="AFFICHAGE_NOEUDS">
    <ELEMENTS_DISPLAY>
        <xsl:apply-templates/>
    </ELEMENTS_DISPLAY>
</xsl:template>

<xsl:template match="AFFICHAGE_ELEMENT">
    <ELEMENT_DISPLAY element="{@element}">
        <xsl:attribute name="type">
            <xsl:choose>
                <xsl:when test="@type='plugin'">
                    <xsl:choose>
                        <xsl:when test="PARAMETRE/@classe='xpages.JEEquationMemoire'">equationmem</xsl:when>
                        <xsl:when test="PARAMETRE/@classe='xpages.JEEquaTeXMemoire'">equatexmem</xsl:when>
                        <xsl:when test="PARAMETRE/@classe='xpages.jeimage.JEImage'">file</xsl:when>
                        <xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="@type='champ'">field</xsl:when>
                <xsl:when test="@type='fichier'">file</xsl:when>
                <xsl:when test="@type='formulaire'">form</xsl:when>
                <xsl:when test="@type='liste'">list</xsl:when>
                <xsl:when test="@type='symbol2'">symbol</xsl:when>
                <xsl:when test="@type='symbole'">symbol</xsl:when>
                <xsl:when test="@type='symbole2'">symbol</xsl:when>
                <xsl:when test="@type='tableau'">table</xsl:when>
                <xsl:when test="@type='tabletexte'">table</xsl:when>
                <xsl:when test="@type='texte'">text</xsl:when>
                <xsl:when test="@type='typesimple'">simpletype</xsl:when>
                <xsl:when test="@type='vide'">empty</xsl:when>
                <xsl:when test="@type='zone'">area</xsl:when>
                <xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
        <xsl:apply-templates/>
    </ELEMENT_DISPLAY>
</xsl:template>

<xsl:template match="VALEUR_SUGGEREE">
    <SUGGESTED_VALUE><xsl:apply-templates/></SUGGESTED_VALUE>
</xsl:template>

<xsl:template match="AFFICHAGE_ATTRIBUT">
    <ATTRIBUTE_DISPLAY attribute="{@attribut}">
        <xsl:apply-templates/>
    </ATTRIBUTE_DISPLAY>
</xsl:template>

<xsl:template match="PLUGIN_INSTRUCTION"></xsl:template>

<xsl:template match="PLUGIN_COMMENTAIRE"></xsl:template>

<xsl:template match="EXPORTS"></xsl:template>

<xsl:template match="STRINGS">
    <STRINGS language="{@langue}">
        <xsl:if test="@pays">
            <xsl:attribute name="country">
                <xsl:value-of select="@pays"/>
            </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates/>
    </STRINGS>
</xsl:template>

<xsl:template match="DESCRIPTION_CONFIG">
    <CONFIG_DESCRIPTION><xsl:apply-templates/></CONFIG_DESCRIPTION>
</xsl:template>

<xsl:template match="STRINGS_MENU">
    <MENU_STRINGS menu="{@menu}">
        <xsl:apply-templates/>
    </MENU_STRINGS>
</xsl:template>

<xsl:template match="TITRE">
    <TITLE><xsl:apply-templates/></TITLE>
</xsl:template>

<xsl:template match="DOCUMENTATION">
    <DOCUMENTATION><xsl:apply-templates/></DOCUMENTATION>
</xsl:template>

<xsl:template match="STRINGS_ELEMENT">
    <ELEMENT_STRINGS element="{@element}">
        <xsl:apply-templates/>
    </ELEMENT_STRINGS>
</xsl:template>

<xsl:template match="STRINGS_ATTRIBUT">
    <ATTRIBUTE_STRINGS attribute="{@attribut}">
        <xsl:apply-templates/>
    </ATTRIBUTE_STRINGS>
</xsl:template>

<xsl:template match="TITRE_VALEUR">
    <VALUE_TITLE value="{@valeur}">
        <xsl:apply-templates/>
    </VALUE_TITLE>
</xsl:template>

<xsl:template match="STRINGS_EXPORT"></xsl:template>

</xsl:stylesheet>
