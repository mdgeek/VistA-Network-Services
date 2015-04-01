RGNETWRR ;RI/CBMI/DKM - Web endpoint for RPC and routine lookup ;01-Apr-2015 11:20;DKM
 ;;1.0;RGSERV WEB SERVER;;1-Apr-2015
 ;=================================================================
 ; RPC lookup entry point
RPC N RPC,RPCX,RTN,TAG,IEN,CCH,LN,X,Y,Z
 S Y="Remote Procedure Inquiry ("_$$UCI^RGUTOS(1)_")"
 D ADDCSS
 D BODY("<title>"_Y_"</title>")
 D BODY("<h1>"_Y_"</h1><br>")
 D BODY("<form method=GET action='RPC'>")
 D BODY("RPC Name: ")
 D BODY("<input name='NAME' type=text autofocus></input>")
 D BODY("<input type=submit value='Search'>")
 D BODY("</form>")
 D BODY("<br><div class='content'/>")
 S RPC=$$GETPARAM^RGNETWWW("NAME"),RPCX=RPC,LN=$L(RPCX)
 Q:'LN
 D BODY("<table>")
 F X="NAME","ENTRY POINT","RETURN TYPE","WRAP","DESCRIPTION" D
 .D BODY("<th>"_X_"</th>")
 F  D  S RPCX=$O(^XWB(8994,"B",RPCX)) Q:$E(RPCX,1,LN)'=RPC
 .F IEN=0:0 S IEN=$O(^XWB(8994,"B",RPCX,IEN)) Q:'IEN  D
 ..D BODY("<tr bgcolor=#"_$$COLOR(.CCH)_">")
 ..S Y=$G(^XWB(8994,IEN,0)),RTN=$P(Y,U,3),TAG=$P(Y,U,2)
 ..D CELL($P(Y,U))
 ..D CELL("<a target='"_$$UCI^RGUTOS(1)_":RTN' href='RTN?NAME="_TAG_U_RTN_$S($L(TAG):"#"_TAG,1:"")_"'>"_$P(Y,U,2,3)_"</a>",1)
 ..D SET($P(Y,U,4),8994,.04)
 ..D SET($P(Y,U,8),8994,.08)
 ..D BODY("<td>")
 ..; Output RPC Description
 ..S Z=0
 ..F X=0:0 S X=$O(^XWB(8994,IEN,1,X)) Q:'X  S Y=$$ESCAPE(^(X,0)) D
 ...I 'Z D
 ....D BODY("<table><tr><td><br><pre>")
 ....S Z=1
 ...D BODY(Y)
 ..D:Z BODY("</pre></td></tr></table>")
 ..; Output Parameter Descriptions
 ..S Z=0
 ..F X=0:0 S X=$O(^XWB(8994,IEN,2,X)) Q:'X  S Y=$$ESCAPE(^(X,0)) D
 ...I 'Z D
 ....D BODY("<table>")
 ....F Z="NAME","TYPE","DESCRIPTION" D BODY("<th>"_Z_"</th>")
 ....S Z=1
 ...D BODY("<tr>")
 ...D CELL($P(Y,U),1)
 ...D SET($P(Y,U,2),8994.02,.02)
 ...D BODY("<td><br><pre>")
 ...F Y=0:0 S Y=$O(^XWB(8994,IEN,2,X,1,Y)) Q:'Y  D BODY($$ESCAPE(^(Y,0))) S Z=2
 ...D:Z'=2 BODY("none")
 ...D BODY("</pre></td></tr>")
 ..D:Z BODY("</table>")
 ..; Output Return Description
 ..S Z=0
 ..F X=0:0 S X=$O(^XWB(8994,IEN,3,X)) Q:'X  S Y=$$ESCAPE(^(X,0)) D
 ...I 'Z D
 ....D BODY("<table><th>RETURN VALUE</th><tr><td><br><pre>")
 ....S Z=1
 ...D BODY(Y)
 ..D:Z BODY("</pre></td></tr></table>")
 ..D BODY("</td></tr>")
 D BODY("</table></div>")
 Q
 ; Routine lookup endpoint
RTN N RTN,TAG,BLD,LN,X,X1,X2,XL,XP,Y
 S Y=$$UCI^RGUTOS(1),X="Routine Inquiry ("_Y_")"
 S RTN=$$GETPARAM^RGNETWWW("NAME"),TAG=" "
 D ADDCSS
 D:'$L(RTN) BODY("<title>"_X_"</title>")
 D:$L(RTN) BODY("<title>"_Y_": "_RTN_"</title>")
 D BODY("<h1>"_X_"</h1><br>")
 D BODY("<form method=GET action='RTN'>")
 D BODY("Routine Name: ")
 D BODY("<input name='NAME' type=text autofocus value='"_RTN_"'></input>")
 D BODY("<input type=submit value='Search'>")
 D BODY("</form>")
 D BODY("<br><div class='content highlight'>")
 Q:'$L(RTN)
 S:RTN[U TAG=$P(RTN,U),RTN=$P(RTN,U,2)
 I '$$TEST^RGUTRTN(RTN) D  Q
 .D BODY("<h2>Routine not found.</h2>")
 I '$L($T(+1^@RTN)) D  Q
 .D BODY("<h2>Source code not found.</h2>")
 D BODY("<pre>")
 F LN=1:1 S X=$T(+LN^@RTN) Q:'$L(X)  D
 .S X1=$P(X," "),X2=$P(X," ",2,9999)
 .S XP=$P(X1,"(",2,999),X1=$P(X1,"("),XL=$L(X1),BLD=X1=TAG
 .S:$L(XP) XP="("_XP
 .D:XL BODY("<a NAME='"_X1_"'></a>")
 .S X1=$$LJ^XLFSTR(X1_XP,8)
 .S:BLD X1="<span class='bold'>"_$E(X1,1,XL)_"</span>"_$E(X1,XL+1,999)
 .D ADDLNK(.X2)
 .S X2=$TR($$ESCAPE^RGNETWWW(X2),$C(1,2),"<>")
 .D BODY(X1_" "_X2)
 D BODY("</pre></div>")
 Q
ADDCSS D BODY("<style>")
 D BODY("body {overflow:hidden}")
 D BODY("input[type=submit] {background:none}")
 D BODY("td {vertical-align: middle}")
 D BODY(".content {position:absolute;top:120px;bottom:0;left:0;right:0;overflow:auto;padding:2px;margin:5px}")
 D BODY(".bold {font-weight:bold;color:red}")
 D BODY(".highlight {background:antiquewhite}")
 D BODY("table {width:100%}")
 D BODY("table, th, td, .highlight {border:1px solid black}")
 D BODY("</style>")
 Q
ADDLNK(TXT) ;
 N P,R,S,C,Q,E,E1,B,PC
 S S=0,Q=0,R=0,E=""
 F P=1:1 D  Q:'$L(C)
 .S C=$E(TXT,P)
 .I C="""" D  Q
 ..I Q,$E(TXT,P+1)="""" S P=P+1 Q
 ..S Q='Q
 .Q:Q
 .I C=";" S P=99999 Q
 .I C="(" S R=R+1
 .I C=")",R S R=R-1
 .D @("AL"_S)
 Q
 ; Looking for branch command
AL0 S B="DGdg"[C
 S:" ."'[C S=1
 Q
 ; Postconditional?
AL1 S PC=C=":",S=$S(PC:3,C=" ":3-B,1:99)
 Q
 ; Collect branch target
AL2 S:'$L(E) E1=P
 I $L(C),"^%"[C!(C?1AN) S E=E_C Q
 D ALX
 S S=$S(R:3,C=",":2,C=" ":0,1:99)
 Q
 ; Expression
AL3 I C=" ",PC S PC=0,S=$S(B:2,1:3)
 E  S S=$S(C="$":4,C=" ":0,1:3)
 Q
 ; Extrinsic?
AL4 S S=$S(C="$":5,C=" ":0,1:3)
 Q
 ; Extrinsic EP
AL5 S:'$L(E) E1=P
 I "^%"[C!(C?1AN) S E=E_C Q
 D ALX
 S S=$S(C=" ":0,1:3)
 Q
 ; Bad syntax
AL99 S P=99999
 Q
 ; Add a link
ALX Q:'$L(E)
 S E=$S(E[U:$P(E,U,1,2),1:E_U_RTN)
 S:E["%" E=$$SUBST^RGUT(E,"%","%25")
 S E=$C(1)_"a href='RTN?NAME="_E_"#"_$P(E,U)_"'"_$C(2),TXT=$E(TXT,1,E1-1)_E_$E(TXT,E1,P-1)_$C(1)_"/a"_$C(2)_$E(TXT,P,9999),P=P+$L(E)+4,E=""
 Q
BODY(X) D ADD^RGNETWWW(X_$C(13,10))
 Q
CELL(X,C) ;
 D BODY("<td align="_$S($G(C):"center",1:"left")_">")
 D BODY(X)
 D BODY("</td>")
 Q
SET(VAL,FIL,FLD) ;
 D CELL($$SET^RGUT(+VAL,$P($G(^DD(FIL,FLD,0)),U,3)_";0:UNKNOWN"),1)
 Q
 ; Return a rotating palette of pastel colors
 ;   CCH = Last color used.
 ;   Returns next color in sequence.
COLOR(CCH) ;
 ;S CCH=$S($G(CCH)="":"FFFFCC",CCH="FFCCFF":"FFCCCC",CCH="CCCCFF":"FFFFCC",1:$E(CCH,5,6)_$E(CCH,1,4))
 ;S CCH=$S($G(CCH)="":"FFFFCC",1:$E(CCH,5,6)_$E(CCH,1,4))
 S CCH=$S($G(CCH)="":"CCFFFF",CCH="FFFFCC":"CCCCFF",CCH="FFCCCC":"CCFFFF",1:$E(CCH,5,6)_$E(CCH,1,4))
 Q CCH
ESCAPE(X) ;
 Q $$ESCAPE^RGNETWWW(X)
