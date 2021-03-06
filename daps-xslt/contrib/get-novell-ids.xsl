<?xml version="1.0"?>
<!--
   Purpose:
     Extracts all ids generated by Novell's FrameMaker
     
   Parameters:
     None
       
   Input:
     Novedoc/DocBook document
     
   Output:
     Debug messages. If there is no @id available, print warning 
     messages
   
   Author:    Thomas Schraitle <toms@opensuse.org>
   Copyright (C) 2012-2015 SUSE Linux GmbH
   
-->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

   <xsl:output method="text"/>
   

 <xsl:template match="*"/>
<xsl:template match="text()"/>

<xsl:template match="/">
   <xsl:apply-templates />
</xsl:template>

<xsl:template match="article|book|part">
    <xsl:call-template name="getid"/>
   <xsl:apply-templates select="chapter|appendix|preface|glossary"/>
</xsl:template>


<xsl:template match="chapter|appendix|preface|glossary">
   <xsl:call-template name="getid"/>
   <xsl:apply-templates select="figure|procedure|example|table"/>
   <xsl:apply-templates select="sect1|sect2|sect3|sect4"/>
</xsl:template>

<xsl:template match="figure|procedure|example|table">
   <xsl:call-template name="getid"/>
   <xsl:apply-templates />
</xsl:template>
   
<xsl:template match="sect1|sect2|sect3|sect4">
  <xsl:call-template name="getid"/>
   <xsl:apply-templates select="figure|procedure|example|table"/>
   <xsl:apply-templates/>
</xsl:template>   
 
<!--<xsl:template match="//procedure/step">
   <xsl:call-template name="getid"/>
</xsl:template>-->
   
<!--<xsl:template match="//orderedlist/listitem/para">
<xsl:call-template name="getid"/>
</xsl:template>-->
<!-- ****************************************** -->
<xsl:template name="getid">
   <xsl:param name="node" select="."/>

   <xsl:choose>
      <xsl:when test="$node/@id">
         <xsl:value-of select="$node/@id"/>
         <xsl:text>&#10;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
         <xsl:message> WARNING: <xsl:value-of select="name($node)"/> doesn't contain an id attribute!</xsl:message>
      </xsl:otherwise>
   </xsl:choose>
</xsl:template>


</xsl:stylesheet>
