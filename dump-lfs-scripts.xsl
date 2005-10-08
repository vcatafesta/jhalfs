<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- XSLT stylesheet to create shell scripts from LFS books. -->

  <!-- Run optional test suites? -->
  <xsl:param name="testsuite" select="0"/>

  <!-- Run toolchain test suites? -->
  <xsl:param name="toolchaintest" select="1"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

  <xsl:template match="sect1">
    <xsl:if test="count(descendant::screen/userinput) &gt; 0 and
      count(descendant::screen/userinput) &gt; count(descendant::screen[@role='nodump'])">
        <!-- The dirs names -->
      <xsl:variable name="pi-dir" select="../processing-instruction('dbhtml')"/>
      <xsl:variable name="pi-dir-value" select="substring-after($pi-dir,'dir=')"/>
      <xsl:variable name="quote-dir" select="substring($pi-dir-value,1,1)"/>
      <xsl:variable name="dirname" select="substring-before(substring($pi-dir-value,2),$quote-dir)"/>
        <!-- The file names -->
      <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
      <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
      <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>
        <!-- The build order -->
      <xsl:variable name="position" select="position()"/>
      <xsl:variable name="order">
        <xsl:choose>
          <xsl:when test="string-length($position) = 1">
            <xsl:text>00</xsl:text>
            <xsl:value-of select="$position"/>
          </xsl:when>
          <xsl:when test="string-length($position) = 2">
            <xsl:text>0</xsl:text>
            <xsl:value-of select="$position"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$position"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
        <!-- Creating dirs and files -->
      <exsl:document href="{$dirname}/{$order}-{$filename}" method="text">
        <xsl:choose>
          <xsl:when test="@id='ch-system-changingowner' or
                    @id='ch-system-creatingdirs' or
                    @id='ch-system-createfiles'">
            <xsl:text>#!/tools/bin/bash&#xA;&#xA;</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>#!/bin/sh&#xA;&#xA;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="sect2[@role='installation'] or
                @id='ch-tools-adjusting' or
                @id='ch-system-readjusting'">
          <xsl:text>cd $PKGDIR &amp;&amp;&#xA;</xsl:text>
        </xsl:if>
        <xsl:apply-templates select=".//para/userinput | .//screen"/>
        <xsl:text>exit</xsl:text>
      </exsl:document>
    </xsl:if>
  </xsl:template>

  <xsl:template match="screen">
    <xsl:if test="child::* = userinput">
      <xsl:choose>
        <xsl:when test="@role = 'nodump'"/>
        <xsl:otherwise>
          <xsl:apply-templates select="userinput" mode="screen"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="para/userinput">
    <xsl:if test="$testsuite != '0' and
            (contains(string(),'test') or
            contains(string(),'check'))">
      <xsl:value-of select="substring-before(string(),'make')"/>
      <xsl:text>make -k</xsl:text>
      <xsl:value-of select="substring-after(string(),'make')"/>
      <xsl:text> &#xA;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput" mode="screen">
    <xsl:choose>
      <xsl:when test="contains(string(),'tar.gz')">
        <xsl:value-of select="substring-before(string(),'tar.gz')"/>
        <xsl:text>tar.bz2</xsl:text>
        <xsl:value-of select="substring-after(string(),'tar.gz')"/>
        <xsl:text> &amp;&amp;&#xA;</xsl:text>
      </xsl:when>
      <xsl:when test="$testsuite = '0' and
                ancestor::sect1[@id='ch-system-coreutils'] and
                (contains(string(),'check') or
                contains(string(),'dummy'))"/>
      <xsl:when test="string() = 'make check' or
                string() = 'make -k check'">
        <xsl:choose>
          <xsl:when test="$toolchaintest = '0'"/>
          <xsl:otherwise>
            <xsl:text>make -k check</xsl:text>
            <xsl:text>&#xA;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains(string(),'glibc-check-log') or
                contains(string(),'test_summary') or
                contains(string(),'expect -c')">
        <xsl:choose>
          <xsl:when test="$toolchaintest = '0'"/>
          <xsl:otherwise>
            <xsl:apply-templates/>
            <xsl:text> &amp;&amp;&#xA;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains(string(),'EOF')">
        <xsl:value-of select="substring-before(string(),'cat &gt;')"/>
        <xsl:text>&#xA;(&#xA;cat &lt;&lt; EOF&#xA;</xsl:text>
        <xsl:apply-templates select="literal"/>
        <xsl:text>&#xA;EOF&#xA;) &gt;</xsl:text>
        <xsl:value-of select="substring-after((substring-before(string(),'&lt;&lt;')),'cat &gt;')"/>
        <xsl:text> &amp;&amp;&#xA;</xsl:text>
        <xsl:if test="string-length(substring-after(string(),'EOF&#xA;')) &gt; 0">
          <xsl:value-of select="substring-after(string(),'EOF&#xA;')"/>
          <xsl:text> &amp;&amp;&#xA;</xsl:text>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
        <xsl:if test="not(contains(string(),'check')) and
                not(contains(string(),'strip '))">
          <xsl:text> &amp;&amp;</xsl:text>
        </xsl:if>
        <xsl:text>&#xA;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="literal">
    <xsl:choose>
      <xsl:when test="contains(string(),'$@')">
        <xsl:variable name="content">
          <xsl:apply-templates/>
        </xsl:variable>
        <xsl:value-of select="substring-before(string($content),'$@')"/>
        <xsl:text>\$@</xsl:text>
        <xsl:value-of select="substring-after(string($content),'$@')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:choose>
      <xsl:when test="ancestor::sect1[@id='ch-system-groff']">
        <xsl:text>$PAGE</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
