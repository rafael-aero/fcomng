<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml">

<xsl:import href="lib.xsl"/>
<xsl:include href="table.xsl"/>

<xsl:output method="html"/>

<!--Stuff needed to get tables to work until properly cleaned up-->
<xsl:template name="anchor"/>
<xsl:param name="table.borders.with.css" select="0"/>

<xsl:key name="ftnote-ids" match="ftnote" use="@lid"/>

<!--* Default template - produces IMPLWARNING *-->

<xsl:template match="*">
  <div class="not-impl">
    <p>
      <xsl:text>IMPLWARNING: </xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:text> is not implemented yet!</xsl:text>
    </p>
    <xsl:if test="node()">
      <p><xsl:text>Content:</xsl:text></p>
      <xsl:value-of select="node()"/>
    </xsl:if>
  </div>
</xsl:template>



<!--* Standard inline elements -->
<!-- (ecam-data|if-installed|tech-label|emph|ein|abb|symbol|
      f-phase|measure|inline-equation|duref|refint|liminaryref|
      context-link)* *-->
<!-- not implemented: ein -->
<!-- not implemented: f-phase -->
<!-- not implemented: liminary-ref -->
<!-- not implemented: context-link -->

<xsl:template match="ecam-data">
  <!-- (ecamsys?,ecamtitle?,ecamsubtitle?) <- all just #PCDATA -->
    <xsl:if test="ecamsys">
      <span class="ecamsys"><xsl:value-of select="ecamsys"/></span> 
    </xsl:if>
    <xsl:if test="ecamtitle">
      <span class="ecamtitle"><xsl:value-of select="ecamtitle"/></span> 
    </xsl:if>
    <xsl:if test="ecamsubtitle">
      <span class="ecamsubtitle"><xsl:value-of select="ecamsubtitle"/></span>
    </xsl:if>
</xsl:template>


<xsl:template match="if-installed">
  <!-- (#PCDATA|emph|abb|f-phase|tech-label)* -->
  <xsl:apply-templates/><img class="ifinstalled" src="../images/if-installed.gif" alt=""/>
</xsl:template>


<xsl:template match="tech-label">
  <!-- (#PCDATA|emph|if-installed)* -->
  <xsl:choose>
    <xsl:when test="@type = 's-page'">
      <span class="ecam_underline"><xsl:apply-templates/></span>
      <xsl:text> SD page</xsl:text>
    </xsl:when>
    <xsl:when test="@type = 'ecamsys'">
      <span class="ecam_underline"><xsl:apply-templates/></span>
    </xsl:when>
    <xsl:when test="@type = 'sel'">
      <xsl:apply-templates/>
      <xsl:text> selector</xsl:text>
    </xsl:when>
    <xsl:when test="@type = 'rotsel'">
      <xsl:apply-templates/>
      <xsl:text> rotary selector</xsl:text>
    </xsl:when>
    <xsl:when test="@type = 'cb'">
      <xsl:apply-templates/>
      <xsl:text> C/B</xsl:text>
    </xsl:when>
    <xsl:when test="@type='keyboard' or @type='key' or
                    @type='instrument' or @type='announcement' or
                    @type = 'panel' or @type='indicator' or
                    @type = 'l-light' or @type='aural-w' or
                    @type = 'tech-label' or @type = 'callout' or
                    @type = 'computer'">
      <xsl:apply-templates/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@type"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="emph">
  <!-- (#PCDATA) -->
  <strong><xsl:apply-templates/></strong>
</xsl:template>


<xsl:template match="abb">
  <!-- (#PCDATA|emph|if-installed)* -->
  <xsl:apply-templates/>
</xsl:template>


<xsl:template match="symbol">
  <!-- EMPTY, but lots of data in attributes
  Need to replace this once images are transformed -->
  <img class="symbol" alt="">
    <xsl:attribute name="src">
      <xsl:value-of select="@href"/>
    </xsl:attribute>
  </img>
</xsl:template>


<xsl:template match="measure">
  <!-- (#PCDATA) -->
  <xsl:choose>
    <xsl:when test="@show-unit = 'false'">
      <xsl:apply-templates/>
    </xsl:when>
    <xsl:when test="@unit = 'FL' or @unit = 'M'">
      <xsl:value-of select="@unit"/>
      <xsl:apply-templates/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates/>
      <xsl:value-of select="@unit"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="inline-equation">
  <!-- ((m:math,equation-image?)) -->
  <!-- equation-image: (fileref) -->
  <!-- fileref: EMPTY -->
  <xsl:choose>
    <xsl:when test="equation-image">
      <img class="equation" alt="equation">
	<xsl:attribute name="src">
	  ../images/<xsl:value-of select="substring-after(equation-image/fileref/@href, '../EXTOBJ/')"/>
	</xsl:attribute>
      </img>
    </xsl:when>
    <xsl:otherwise>
      <div class="not-impl">
	<p>IMPLWARNING: Equation without image. m:math is not yet implemented!</p>
      </div>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="duref">
  <!-- (linktext?) -->
  <!-- linktext is subset of standard inline -->
  <xsl:choose>
    <xsl:when test="@product = 'FCOM'">
      <a class="duref">
        <xsl:attribute name="href">
          <xsl:value-of select="@ref"/>
        </xsl:attribute>
        <xsl:value-of select="linktext"/>
      </a>
    </xsl:when>
    <xsl:otherwise>
      <span class="duref">
        <xsl:text>Refer to </xsl:text>
        <xsl:choose>
          <xsl:when test="linktext">
            <xsl:value-of select="@product"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="linktext"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="fullref">
              <xsl:value-of select="@product"/>/<xsl:value-of select="@ref"/>
            </xsl:variable>
            <xsl:variable name="reftext">
              <xsl:value-of select="document('external_duref.xml')/external/duref[@ref=$fullref]"/>
            </xsl:variable>
            <xsl:message><xsl:value-of select="$fullref"/>: <xsl:value-of select="$reftext"/></xsl:message>
            <xsl:choose>
              <xsl:when test="$reftext">
                <xsl:value-of select="$reftext"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$fullref"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </span>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="refint">
  <!-- (#PCDATA|symbol)* -->
  <xsl:variable name="footnote_id">
    <xsl:value-of select="generate-id(key('ftnote-ids', @ref))"/>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="name(key('ftnote-ids', @ref)) = 'ftnote'">
      <a class="footnoteref">
        <xsl:attribute name="href">#fnid<xsl:value-of select="$footnote_id"/></xsl:attribute>
        <xsl:text>(</xsl:text>
        <xsl:value-of select="count(key('ftnote-ids', @ref)/preceding-sibling::ftnote) + 1"/>
        <xsl:text>)</xsl:text>
      </a>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>See </xsl:text>
      <xsl:apply-templates/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--** Standard inline elements/* *-->
<!-- not implemented: m:math -->


<!--* Standard block level elements -->
<!-- (para|unlist|numlist|warning|caution|note|table|graphref|
     launcher|equal|whatif|equation|example|assumption|comment|reason)*)-->
<!-- graphref implemented in graphref section *-->
<!-- launcher not implemented -->
<!-- whatif not implemented -->
<!-- assumption not implemented -->

<xsl:template match="para">
  <!-- (Standard inline elements)+ -->
  <p><xsl:apply-templates/></p>
</xsl:template>


<xsl:template match="unlist">
  <!-- ((title?,para?,item+)) -->
  <xsl:apply-templates select="title|para"/>
  <xsl:element name="ul">
    <xsl:attribute name="class">
      <xsl:value-of select="@bulltype"/>
    </xsl:attribute>
    <xsl:apply-templates select="item"/>
  </xsl:element>
</xsl:template>


<xsl:template match="numlist">
  <!-- ((title?,para?,item+)) -->
  <xsl:apply-templates select="title|para"/>
  <xsl:element name="ol">
    <xsl:attribute name="class">
      <xsl:value-of select="@format"/>
    </xsl:attribute>
    <xsl:apply-templates select="item"/>
  </xsl:element>
</xsl:template>


<xsl:template match="warning">
  <!-- (((para|unlist|numlist|equal)+|desc-cond)+)-->
  <div class="caution">
    <h2>Warning</h2>
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="caution">
  <!-- (((para|unlist|numlist|equal)+|desc-cond)+) -->
  <div class="caution">
    <h2>Caution</h2>
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="note">
  <!-- ((((para|unlist|numlist|equal)+|desc-cond)+|graphref)+) -->
  <div class="note">
    <h2>Note</h2>
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="table">
  <!-- ((title?, (tgroup+|graphref),footnotes?))-->
  <div class="table">
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="equal">
  <!-- (equ-l,equ-r) -->
  <xsl:if test="name(preceding-sibling::*[1]) != 'equal'">
    <div class="equal">
    <table class="equal">
      <xsl:call-template name="recursive-process-equal">
        <xsl:with-param name="equal-node" select="."/>
      </xsl:call-template>
    </table>
    </div>
  </xsl:if>
</xsl:template>


<xsl:template name="recursive-process-equal">
  <xsl:param name="equal-node"/>
	<tr>
	  <th class="equ-l">
	    <xsl:apply-templates select="$equal-node/equ-l"/>
	  </th>
	  <td class="equ-r">
	    <xsl:apply-templates select="$equal-node/equ-r"/>
	  </td>
	</tr>
   <xsl:if test="name($equal-node/following-sibling::*[1]) = 'equal'">
     <xsl:call-template name="recursive-process-equal">
       <xsl:with-param name="equal-node" select="$equal-node/following-sibling::equal[1]"/>
     </xsl:call-template>
   </xsl:if>
</xsl:template>


<xsl:template match="equation">
  <!-- ((m:math,equation-image?)) -->
  <!-- equation-image: (fileref) -->
  <!-- fileref: EMPTY -->
  <xsl:choose>
    <xsl:when test="equation-image">
      <img class="equation" alt="equation">
	<xsl:attribute name="src">
	  ../images/<xsl:value-of select="substring-after(equation-image/fileref/@href, '../EXTOBJ/')"/>
	</xsl:attribute>
      </img>
    </xsl:when>
    <xsl:otherwise>
      <div class="not-impl">
	<p>IMPLWARNING: Equation without image. m:math is not yet implemented!</p>
      </div>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="example">
  <!-- (((para|unlist|numlist|equal)+|equation)+) -->
  <div class="example">
    <h2>Example</h2>
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="comment">
  <!-- (Standard block elements) -->
  <xsl:choose>
    <xsl:when test="note|caution|warning">
      <xsl:apply-templates/>
    </xsl:when>
    <xsl:otherwise>
      <div class="note">
	<xsl:apply-templates/>
      </div>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="reason">
  <!-- (para|unlist|numlist)+ -->
  <div class="note">
    <h2>Reason</h2>
    <xsl:apply-templates/>
  </div>
</xsl:template>


<!--** Standard block level elements/* -->
<!-- (title|item|footnotes|equ-l|equ-r) -->
<!-- desc-cond implemented in description subsection *-->
<!-- tgroup implemented in table.xsl -->

<xsl:template match="title">
  <!-- (Standard inline elements)* -->
  <h1><xsl:apply-templates/></h1>
</xsl:template>


<xsl:template match="item">
  <!-- (Standard block elements)+ -->
  <li><xsl:apply-templates/></li>
</xsl:template>


<xsl:template match="footnotes">
  <!-- (ftnote+) -->
  <div class="footnotes">
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="equ-l|equ-r">
  <!-- equ-l: (Standard inline elements)* -->
  <!-- equ-r: ((para|unlist|numlist|warning|caution|note)+) -->
  <xsl:apply-templates/>
</xsl:template>



<!--*** Standard block level elements/*/* -->
<!-- (ftnote) *-->

<xsl:template match="ftnote">
  <!-- ((para|unlist|numlist|equal)+) -->
  <span class="footnotenum">
  <xsl:attribute name="id">fnid<xsl:value-of select="generate-id()"/></xsl:attribute>
  (<xsl:number/>)
  </span>
  <div class="footnotetext"><xsl:apply-templates/></div>
</xsl:template>



<!--* graphref *-->
<!-- graphref/linktext not implemented -->
<!-- graphref/unanchored-graphics not implemented -->
<!-- graphref/interactive-graphic/hotspot-links not implemented -->

<xsl:template match="graphref">
  <!-- ((linktext?,interactive-graphic,unanchored-graphics?)) -->
  <xsl:apply-templates/>
</xsl:template>


<xsl:template match="interactive-graphic">
  <!-- (illustration,hotspot-links?) -->
  <xsl:apply-templates/>
</xsl:template>


<xsl:template match="illustration">
  <!-- illustration: (title?, (sheet+)) -->
  <xsl:if test="title">
    <h2 class="image_title"><xsl:apply-templates select="title/node()"/></h2>
  </xsl:if>
  <xsl:apply-templates select="sheet"/>
</xsl:template>


<xsl:template match="sheet">
  <!-- ((fileref,gcompanionref?,gdesc?)) -->
  <div class="image">
    <img alt="cgm">
      <xsl:attribute name="src">
	<xsl:value-of select="fileref/@href"/>
      </xsl:attribute>
    </img>
    <xsl:apply-templates select="gdesc"/>
  </div>
</xsl:template>


<xsl:template match="gdesc">
  <!-- (desctext?,listitem?) -->
  <div class="callout-list"><xsl:apply-templates/></div>
</xsl:template>


<xsl:template match="desctext">
  <!-- (paradesc+) -->
  <!-- paradesc: (standard-inline|gritem) -->
  <xsl:for-each select="paradesc">
    <p><xsl:apply-templates/></p>
  </xsl:for-each>
</xsl:template>


<xsl:template match="gdesc/listitem">
  <!-- (grdescitem+) -->
  <!-- grdescitem: (gritem,title?,itembody?) -->
  <table class="callouts">
    <xsl:for-each select="grdescitem">
      <tr class="callout" valign="top">
	<th class="callout"><xsl:apply-templates select="gritem"/></th>
	<td class="callout">
	  <xsl:if test="title">
	    <xsl:apply-templates select="title"/>
	  </xsl:if>
	<xsl:apply-templates select="itembody"/></td>
      </tr>
  </xsl:for-each>
  </table>
</xsl:template>


<xsl:template match="gritem">
  <!-- gritem (#PCDATA|emph|if-installed)* -->
  <xsl:apply-templates/>
</xsl:template>


<xsl:template match="itembody">
  <!-- (standard block items)* -->
  <xsl:apply-templates/>
</xsl:template>


<!--* description -->
<!-- (description | descbody | ex_desc_cond | descitem | desc-cond |
     desc-cond/intro | desc-cond/condbody) *-->
<!-- hatref not implemented -->
<!-- perfoapplication not implemented -->
<xsl:template match="description">
  <!-- description: (reason?,title, (descbody|descitem),descitem*) -->
  <xsl:param name="group_pos"/>
  <xsl:param name="group_title"/>
  <xsl:choose>
    <xsl:when test="$group_pos = -1">
      <xsl:apply-templates select="title"/>
    </xsl:when>
    <xsl:when test="$group_pos = 0">
      <h1><xsl:value-of select="$group_title"/></h1>
    </xsl:when>
  </xsl:choose>
  <xsl:if test="not(contains(title, 'Paper') and
                contains(title, 'Only'))">
    <xsl:apply-templates select="descbody|descitem"/>
  </xsl:if>
</xsl:template>


<xsl:template match="descbody|ex-desc-cond">
  <!-- descbody: (standard_block|desc-cond|ex-desc-cond) -->
  <!-- ex-desc-cond: (desc-cond,desc-cond+) -->
  <xsl:apply-templates/>
</xsl:template>


<xsl:template match="descitem">
  <!-- (title, (descbody|descitem),descitem*) -->
  <div class="descitem">
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="desc-cond">
  <!-- (intro,condbody) -->
  <div class="desccond">
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="desc-cond/intro">
  <!-- (standard_inline) -->
  <div class="intro">
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="desc-cond/condbody">
  <!-- (standard_block | desc_cond | ex_desc_cond)* -->
  <div class="condbody">
    <xsl:apply-templates/>
  </div>
</xsl:template>


<!--* normalproc
    normalproc | xtitle | procitem | procdesc | ecam-info
    procbody implemented in own section *-->
<!-- hatref not implemented -->
<!-- perfoapplication not implemented -->
<!-- starting-point not implemented -->

<xsl:template match="normalproc">
  <!--(reason?,xtitle,procdesc?,
  (procbody|procitem),procitem*)-->
  <xsl:param name="group_pos"/>
  <xsl:param name="group_title"/>
  <xsl:if test="$group_pos = -1">
    <xsl:apply-templates select="xtitle"/>
  </xsl:if>
  <xsl:if test="$group_pos = 0">
    <h1><xsl:value-of select="$group_title"/></h1>
  </xsl:if>

  <xsl:apply-templates select="procdesc|procbody|procitem"/>
</xsl:template>


<xsl:template match="xtitle">
  <!-- (ecamsystem?,title,subtitle*) -->
  <h1>
    <xsl:attribute name="class">
      <xsl:choose>
        <xsl:when test="title/@ecamimportance='A'">
          <xsl:text>amber</xsl:text>
        </xsl:when>
        <xsl:when test="title/@ecamimportance='R'">
          <xsl:text>red</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:attribute>
    <xsl:if test="ecamsystem">
      <span class="ecam_underline">
        <xsl:value-of select="ecamsystem"/>
      </span>
      <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="title/node()"/>
    <xsl:for-each select="subtitle">
      <xsl:apply-templates/>
    </xsl:for-each>
  </h1>
</xsl:template>


<xsl:template match="procitem">
  <!-- (title,procdesc?, (procbody|procitem),procitem*) -->
  <div class="procitem">
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="procdesc">
  <!-- standard_block_items -->
  <div class="procdesc">
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="ecam-info">
  <!-- (para+,comment?) -->
  <xsl:apply-templates/>
</xsl:template>


<!--* procbody
    procbody | action | action-block | limit | inform | condition | ex-conditions *-->
<!-- line is not implemented -->

<xsl:template match="procbody">
  <!-- ((((action|action-block|limit|inform|condition|ex-conditions|line)+))+) -->
  <div class="procbody">
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="action">
  <!-- (((cr-action|command),comment?)) -->
  <xsl:apply-templates/>
</xsl:template>


<xsl:template match="action-block">
  <!-- (title?, (action,action+)) -->
  <div class="actionblock">
    <xsl:if test="title">
      <h2><xsl:apply-templates select="title"/></h2>
    </xsl:if>
    <xsl:for-each select="action">
      <xsl:apply-templates/>
    </xsl:for-each>
  </div>
</xsl:template>

<xsl:template match="action-block/title">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="limit">
  <!-- ((lit-limit|perf-value),comment?) -->
  <xsl:apply-templates/>
</xsl:template>


<xsl:template match="inform">
  <!-- (standard_block | cautionproc | noteproc | warningproc ) -->
  <xsl:apply-templates/>
</xsl:template>


<xsl:template match="condition">
  <!-- ((intro|introblock),procdesc?,procbody,endofproc?) -->
  <div>
    <xsl:attribute name="class">
      <xsl:text>condition</xsl:text>
      <xsl:if test="@at-any-time = 'true'">
        <xsl:text> anytime</xsl:text>
      </xsl:if>
    </xsl:attribute>
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="ex-conditions">
  <!-- (condition,condition+) -->
  <xsl:apply-templates/>
</xsl:template>


<!--** procbody/*//*
    cr-action | challenge | response | commmand | lit-limit | perf-value |
    cautionproc | noteproc | warningproc | intro | introblock *-->
<!-- extobject not implemented -->
<!-- extapplication not implemented -->
<!-- field not implemented -->
<!-- endofproc not implemented -->


<xsl:template match="cr-action">
  <!-- (challenge,response) -->
  <div class="cr">
    <table class="cr"><tr>
      <td class="cr-left">
	<xsl:apply-templates select="challenge"/>
      </td>
      <td class="cr-dots"><div class="dots"> </div></td>
      <td class="cr-right">
	<xsl:apply-templates select="response"/>
      </td>
    </tr></table>
  </div>
</xsl:template>


<xsl:template match="cr-action/challenge|cr-action/response">
  <!-- challenge: standard_inline -->
  <!-- response: (#PCDATA|extobject|extapplication|field)* -->
  <xsl:apply-templates/>
</xsl:template>


<xsl:template match="command">
  <!-- standard_block_elements -->
  <div class="command">
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="lit-limit">
  <!-- standard_inline_elements -->
  <p><strong><xsl:apply-templates/></strong></p>
</xsl:template>


<xsl:template match="perf-value">
  <!-- (perf,value) <- Both standard inline -->
  <p><strong><xsl:apply-templates select="perf"/>:</strong>  <xsl:apply-templates  select="value"/></p>
</xsl:template>


<xsl:template match="cautionproc">
  <!-- standard_block | (action|action-block|limit|inform|condition|ex-conditions|line) -->
  <div class="caution">
    <h2>Caution</h2>
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="noteproc">
  <!-- standard_block | (action|action-block|limit|inform|condition|ex-conditions|line) -->
  <div class="note">
    <h2>Note</h2>
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="warningproc">
  <!-- standard_block | (action|action-block|limit|inform|condition|ex-conditions|line) -->
  <div class="caution">
    <h2>Warning</h2>
    <xsl:apply-templates/>
  </div>
</xsl:template>


<xsl:template match="intro">
  <!-- standard_inline -->
  <p class="intro">
    <xsl:text>&#x2022; </xsl:text>
    <xsl:apply-templates/>
  </p>
</xsl:template>


<xsl:template match="introblock">
  <!-- (intro, intro+) -->
  <!-- intro:standard_inline -->
  <p class="intro">
    <xsl:text>&#x2022; </xsl:text>
    <xsl:for-each select="intro">
      <xsl:if test="preceding-sibling::intro">
        <xsl:text> </xsl:text>
        <xsl:value-of select="../@operator"/>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:for-each>
  </p>
</xsl:template>






<!--* Yet to be sorted *-->




<xsl:template match="abnormalproc|emergencyproc">
<!-- abnormalproc: ((reason?,xtitle,annunciation?,procdesc?,procbody?,procitem*,fwspage?)) -->
<!-- emergencyproc: ((reason?,xtitle,annunciation?,procdesc?,procbody?,procitem*, fwspage?)) -->
  <xsl:param name="group_pos"/>
  <xsl:if test="$group_pos &lt; 1">
    <xsl:apply-templates select="xtitle"/>
  </xsl:if>
  <xsl:apply-templates select="annunciation|procdesc|procbody|procitem|fwspage"/>
</xsl:template>


<xsl:template match="land">
  <p>
    <xsl:attribute name="class">
      <xsl:value-of select="@type"/>
    </xsl:attribute>
    <xsl:choose>
      <xsl:when test="@type = 'landasap'">
	LAND ASAP
      </xsl:when>
      <xsl:otherwise>
	LAND type not implemented yet!
      </xsl:otherwise>
    </xsl:choose>
  </p>
</xsl:template>


<xsl:template match="performance">
  <!-- (reason?,title, (perfbody|perfitem),perfitem*) -->
  <xsl:param name="group_pos"/>
  <xsl:param name="group_title"/>
  <xsl:if test="$group_pos = -1">
    <xsl:apply-templates select="title"/>
  </xsl:if>
  <xsl:if test="$group_pos = 0">
    <h1><xsl:value-of select="$group_title"/></h1>
  </xsl:if>
  <xsl:apply-templates select="perfbody|perfitem"/>
</xsl:template>


<xsl:template match="limitation">
<!-- (reason?,title, (limitbody|limititem),limititem*) -->
  <xsl:param name="group_pos"/>
  <xsl:param name="group_title"/>
  <xsl:if test="$group_pos = -1">
    <xsl:apply-templates select="title"/>
  </xsl:if>
  <xsl:if test="$group_pos = 0">
    <h1><xsl:value-of select="$group_title"/></h1>
  </xsl:if>
  <xsl:apply-templates select="limitbody|limititem"/>
</xsl:template>


<xsl:template match="equ-l|equ-r|row-header|
		     limitbody|
		     perf|value|limititem|
		     perfbody|perfitem">
  <xsl:apply-templates/>
</xsl:template>


<xsl:template match="associated-procs">
  <div class="associated-procs">
    <h1>Associated Procedures</h1>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="associated-proc">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="associated-proc/xtitle">
  <xsl:if test="ecamsystem">
    <span class="ecamsys"><xsl:value-of select="ecamsystem"/></span> 
  </xsl:if>
  <span class="ecamtitle"><xsl:value-of select="title"/></span> 
  <xsl:apply-templates select="title/*"/>
  <xsl:if test="subtitle">
    <span class="ecamsubtitle"><xsl:value-of select="subtitle"/></span>
  </xsl:if>
</xsl:template>

<xsl:template match="secondary-failures">
  <div class="secondary-failures">
    <h1>Secondary Failures</h1>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="ecampage">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ecamsyspage">
  <p><xsl:apply-templates/></p>
</xsl:template>

<!-- fwspage -->

<xsl:template match="fwspage">
  <!-- (limitations?,deferredproc?,status?,moreinfopage?,memopage?) -->
  <div class="fwspage">
    <xsl:apply-templates/>
  </div>
</xsl:template>

<!-- fwspage/* -->
<!-- not implemented: moreinfopage -->
<!-- not implemented: memopage -->

<xsl:template match="limitations">
  <div class="limitations">
    <h1>Limitations:</h1>
    <!-- (ecamlimit?,pfdlimit?,comment?) -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="deferredproc">
  <div class="deferred-proc">
    <h1>Deferred procedures:</h1>
    <!-- ((allphase-proc|flightphase-proc)+,comment?) -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="status">
  <div class="status">
    <h1>Status:</h1>
    <!-- (ecaminopsys?,otherinopsys?,info?,comment?) -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<!-- fwspage/*/* -->

<xsl:template match="ecamlimit">
  <div class="ecamlimit">
    <!-- (((allphase-limit|flightphase-limit)+,comment?)) -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="pfdlimit">
  <div class="pfdlimit">
    <!-- (((allphase-limit|flightphase-limit)+,comment?)) -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="allphase-proc">
  <div class="all-phase">
    <!-- ((procbody+,comment?)) -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="flightphase-proc">
  <div class="flight-phase">
    <!-- ((procbody+,comment?)) -->
    <h2 class="flightphase"><xsl:value-of select="@pof"/></h2>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="ecaminopsys">
  <div class="ecaminop">
    <h1>Inop systems:</h1>
    <!-- (((duref| (allphase-sys|flightphase-sys)+),comment?)) -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="otherinopsys">
  <div class="otherinop">
    <h1>Inop systems not displayed by ECAM:</h1>
    <!-- (((duref|(allphase-sys|flightphase-sys)+),comment?)) -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="info">
  <div class="info">
    <h1>Info:</h1>
    <!-- (((infobody|info-cond),comment?)+) -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<!-- fwspage/*/*/* -->
<!-- not implemented: flightphase-limit -->
<!-- not implemented: flightphase-sys -->

<xsl:template match="allphase-limit">
  <!-- (((limit|condlimit),comment?)+) -->
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="allphase-sys">
  <div class="all-phase">
    <!-- comment | condsys | sys -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="infobody">
  <!-- subset of standard block -->
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="info-cond">
  <!-- ((intro|introblock),info-condbody) -->
    <xsl:apply-templates select="intro|introblock"/>
    <xsl:apply-templates select="info-condbody"/>
</xsl:template>


<!-- fwspage/*/*/*/* -->
<!-- not implemented: allphase-limit -->
<!-- not implemented: flightphase-limit-->

<xsl:template match="limit">
  <!-- ((lit-limit|perf-value),comment?) -->
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="condlimit">
  <!-- ((intro|introblock),condlimitbody) -->
  <xsl:apply-templates select="intro|introblock"/>
  <xsl:apply-templates select="condlimitbody"/>
</xsl:template>

<xsl:template match="condsys">
  <div class="condsys">
    <!-- (intro | introblock), condsysbody -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="sys">
  <div class="sys">
    <!-- standard inline -->
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="info-condbody">
  <!-- ((infobody+,comment?)) -->
  <div class="condbody">
    <xsl:apply-templates/>
  </div>
</xsl:template>

<!-- fwspage/*/*/*/*/* -->
<!-- not implemented: lit-limit -->
<!-- not implemented: perf-value -->

<xsl:template match="condlimitbody">
  <!-- (limit|lit-limit)+ -->
  <div class="condbody">
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="condsysbody">
  <!-- (sys+) -->
  <div class="condbody">
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="infobody">
  <!-- standard block -->
  <xsl:apply-templates/>
</xsl:template>


<!-- approbation -->
<xsl:template match="approbation">
  <!-- (reason?,title,
  (tr-data|env-data|heading-data|bulletin-data),approbation-frame?
  ,approbation-area?)-->
  <xsl:apply-templates select="title"/>
  <xsl:if test="approbation-area/approved-by/job-title">
    <h2>Approved by: -<xsl:value-of select="approbation-area/approved-by/job-title"/></h2>
  </xsl:if>
  <xsl:apply-templates select="bulletin-data"/>
</xsl:template>

<!-- approbation/* -->
<!-- not implemented: tr-data -->
<!-- not implemented: env-data -->
<!-- not implemented: heading-data -->
<!-- not implemented: approbation-frame -->

<xsl:template match="bulletin-data">
  <!-- (reason-for-issue,applicable-to?,bul-cancelled-by?) -->
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="approbation-area">
  <!--(approbation-authority?,approval-date,approval-reference,
  approved-by?)-->
  <div class="approbation">
    <h1>Approbation:</h1>
    <xsl:apply-templates/>
  </div>
</xsl:template>


<!-- approbation/*/* -->

<xsl:template match="reason-for-issue">
  <!-- subset of standard block elements -->
  <div class="reason">
    <h1>Reason for issue:</h1>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="applicable-to">
  <!-- subset of standard block elements -->
  <div class="applicable">
    <h1>Applicable to:</h1>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="bul-cancelled-by">
  <!-- subset of standard block elements -->
  <div class="cancelled-by">
    <h1>Cancelled by:</h1>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="approbation-authority">
  <!-- (#PCDATA) -->
  <p>Authority: <xsl:apply-templates/></p>
</xsl:template>

<xsl:template match="approval-date">
  <!-- (#PCDATA) -->
  <p>Date: <xsl:apply-templates/></p>
</xsl:template>

<xsl:template match="approval-reference">
  <!-- (#PCDATA) -->
  <p>Reference: <xsl:apply-templates/></p>
</xsl:template>

<xsl:template match="approved-by">
  <!--(name?,job-title?,approval-comment?)-->
  <p>Approved by:
  <xsl:choose>
    <xsl:when test="name and job-title">
      <xsl:value-of select="name"/>, <xsl:value-of select="job-title"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="name"/>
      <xsl:value-of select="job-title"/>
    </xsl:otherwise>
  </xsl:choose>
  </p>
  <xsl:if test="approval-comment">
    <p> <xsl:value-of select="approval-comment"/></p>
  </xsl:if>
</xsl:template>

<!-- work-example -->

<xsl:template match="work-example">
  <!--(title?,
  (((para|unlist|numlist|warning|caution|note)+|table|graphref|
  launcher|equal)+|desc-cond|ex-desc-cond|workex-item)+)-->
  <div class="example">
    <h1>Example</h1>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<!-- synthesisitem -->

<xsl:template match="synthesisitem">
  <!-- (reason?,title,table) -->
  <xsl:param name="group_pos"/>
  <xsl:param name="group_title"/>
  <xsl:choose>
    <xsl:when test="$group_pos = -1">
      <xsl:apply-templates select="title"/>
    </xsl:when>
    <xsl:when test="$group_pos = 0">
      <h1><xsl:value-of select="$group_title"/></h1>
    </xsl:when>
  </xsl:choose>
  <div class="synthesisitem">
    <xsl:apply-templates select="table"/>
  </div>
</xsl:template>

<!-- procsynthesis -->

<xsl:template match="procsynthesis">
  <!--(reason?,xtitle,procsynthbody)-->
  <div class="procsynthesis">
    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="procsynthbody">
  <!--(table+)-->
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="condintro">
  <!-- standard in-line -->
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="role">
  <!-- EMPTY -->
  <xsl:value-of select="@name"/>
</xsl:template>



</xsl:stylesheet>
