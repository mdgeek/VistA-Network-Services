RGNETTCP ;RI/CBMI/DKM - TCP Connection Manager ;08-Jun-2015 15:13;DKM
 ;;1.0;NETWORK SERVICES;;29-Mar-2015
 ;=================================================================
 ; Start a primary listener
START(RGCFG) ;
 D SSLIS(RGCFG,1)
 Q
 ; Stop a primary listener
STOP(RGCFG) ;
 D SSLIS(RGCFG,0)
 Q
 ; Restart a primary listener
RESTART(RGCFG) ;
 D STOP(.RGCFG),START(.RGCFG)
 Q
 ; Start all primary listeners
STARTALL D SSALL(1)
 Q
 ; Stop all primary listeners
STOPALL D SSALL(0)
 Q
 ; Restart all primary listeners
RESTALL D STOPALL,STARTALL
 Q
 ; List the status of all primary listeners
LISTALL N RGCFG,LP,X
 F LP=0:0 S LP=$O(^RGNET(996.5,LP)) Q:'LP  D
 .K RGCFG
 .S RGCFG=LP
 .D GETCFG(.RGCFG)
 .S X=$$STATE
 .W RGCFG("name")," (",RGCFG("port"),") is",$S(X:"",1:" not")," running.",!!
 Q
 ; Start/stop all registered listeners
 ; SS - 1 = start, 0 = stop
 ; SL - true = silent mode
SSALL(SS,SL) ;
 N RGCFG
 F RGCFG=0:0 S RGCFG=$O(^RGNET(996.5,RGCFG)) Q:'RGCFG  D SSLIS(RGCFG,SS,.SL)
 Q
 ; Start/stop primary listener
 ; SS - 1 = start, 0 = stop
 ; SL - true = silent mode
SSLIS(RGCFG,SS,SL) ;
 N $ET,SAME,RGMODE
 Q:'$$GETCFG(.RGCFG)
 S SL=$G(SL,$D(ZTQUEUED))
 S:'SL $ET="D SSERR^RGNETTCP"
 W:'SL RGCFG("name")," (",RGCFG("port"),"): "
 S SAME=$$STATE=SS
 S:'SS @$$LOCKNODE(.RGCFG)=1
 I SAME W:'SL $S(SS:"already",1:"not")," running.",!!  Q
 I SS,RGCFG("disabled") W:'SL "disabled.",!! Q
 D:SS JOB(0,.RGCFG)
 Q:SL
 N P1,P2,LP
 S P1=$S(SS:"start",1:"stop"),P2=P1_$S(SS:"ed",1:"ped")
 W "waiting for ",P1," signal..."
 F LP=1:1:5 D
 .H 2
 .W "."
 .S:$$STATE=SS LP=99
 I LP<99 W " failed to ",P1,".",!!
 E  W " ",P2,".",!!
 Q
SSERR W "failed: ",$$EC^%ZOSV,!!
 D UNWIND^%ZTER
 Q
 ; Fetch listener configuration
 ; Populates RGCFG with configuration data.
 ; Returns listener IEN
GETCFG(RGCFG) ;
 Q:$D(RGCFG)=11 RGCFG
 S U="^"
 S:RGCFG'=+RGCFG RGCFG=+$O(^RGNET(996.5,"B",RGCFG,0))
 I RGCFG D
 .N N0,LP
 .S N0=^RGNET(996.5,RGCFG,0),RGCFG("handler")=$G(^(10))
 .F LP=1:1:5 S RGCFG($P("name^port^uci^disabled^maximum",U,LP))=$P(N0,U,LP)
 Q:$Q RGCFG
 Q
 ; Entry point for GT.M socket dispatch
GTMEP D EN(2,$ZCM)
 Q
 ; Start listener as background process
 ; Returns true if operation was successful.
JOB(RGMODE,RGCFG) ;
 N SUCCESS
 I RGMODE>1 S SUCCESS=0
 E  I '$$GETCFG(.RGCFG) S SUCCESS=0
 E  I RGMODE=1 D
 .I RGOS D
 ..N SOCK
 ..S SOCK=$P($KEY,"|",2)
 ..X "U RGTDEV:detach=SOCK"
 ..S SOCK="""SOCKET:"_SOCK_""""
 ..X "J EN^RGNETTCP(RGMODE,RGCFG):(input="_SOCK_":output="_SOCK_")"
 ..S SUCCESS=$T
 .E  D
 ..X "J EN^RGNETTCP(RGMODE,RGCFG):(:4:RGTDEV:RGTDEV):15"
 ..S SUCCESS=$T
 E  I $L(RGCFG("uci")) D
 .X "J EN^RGNETTCP(RGMODE,RGCFG)[RGCFG(""uci"")]"
 .S SUCCESS=$T
 E  D
 .J EN^RGNETTCP(RGMODE,RGCFG)
 .S SUCCESS=$T
 Q:$Q SUCCESS
 Q
 ; Start listener process (primary and secondary)
 ;   RGMODE = Connection type:
 ;     0: primary listener   - dispatches connections
 ;     1: secondary listener - dispatched by primary listener
 ;     2: secondary listener - dispatched by OS
 ;     3: debug listener     - debug mode listener
 ;   RGCFG = Listener name or IEN
EN(RGMODE,RGCFG) ;
 N RGTDEV,RGQUIT,RGRETRY,RGOS,DUZ,$ET,$ES
 S DT=$$DT^XLFDT,$ET="D ETRAP1^RGNETTCP"
 D:'$$GETCFG(.RGCFG) RAISE("Unknown listener.")
 Q:RGCFG("disabled")
 S (RGQUIT,RGRETRY)=0,RGOS=$$OS
 D:RGOS<0 RAISE("Unsupported operating system.")
 I 'RGOS,RGMODE=2 D BADMODE                                            ; Cache does not support mode 2
 Q:$$STATE                                                             ; Quit if listener already running
 D CLEANUP,STSAVE(0),NULLOPEN,STSAVE(1)                                ; Initialize environment
 D CHPRN(.RGCFG)                                                       ; Change process name
 F  D LISTEN Q:RGQUIT>0!RGMODE                                         ; Main loop
 D STATE(0),STREST(1),^%ZISC,STREST(0),CLEANUP
 Q
 ; Entry point for interactive debugging
DEBUG N PORT,CFG
 D TITLE^RGUT("Debug Mode Support",$P($T(+2),";",3))
 F  D  Q:$D(CFG)
 .S CFG=$$ENTRY^RGUTLKP(996.5,,"Enter listener name: ")
 .W !
 .Q:CFG'>0
 .D GETCFG(.CFG)
 .I CFG("disabled") W "That listener is disabled.  Try again.",! K CFG
 Q:CFG'>0
 S PORT=$$PMPT("Port","Enter listener port.",CFG("port"))
 Q:U[PORT
 S CFG("port")=PORT
 I $L($T(^%Serenji)),$$ASK^RGUT("Use Serenji Debugger","Y") D  Q
 .N SRJIP,SRJPORT
 .S SRJIP=$$PMPT("Serenji Listener Addr","Enter Serenji listener address",IP)
 .Q:U[SRJIP
 .S SRJPORT=$$PMPT("Serenji Listener Port","Enter Serenji listener port",4321)
 .Q:U[SRJPORT
 .D DEBUG^%Serenji("EN^RGNETTCP(3,.CFG)",SRJIP,SRJPORT)
 W !,"Now listening on port ",CFG("port"),!
 D EN(3,.CFG)
 Q
 ; Prompt for user input
PMPT(PMPT,HELP,DFLT) ;
 N RET
 F  D  Q:$D(RET)
 .W PMPT,": ",$S($D(DFLT):DFLT_"// ",1:"")
 .R RET:$G(DTIME,30)
 .E  S RET=U
 .I $D(DFLT),'$L(RET) S RET=DFLT W DFLT
 .W !
 .I RET["?" W !,HELP,!! K RET
 Q RET
 ; Determine operating system
 ; Returns 0 = Cache, 1 = GT.M, -1 = unknown
OS() N OS
 S U="^",OS=$P($G(^%ZOSF("OS")),U)
 Q $S(OS["OpenM":0,OS["GT.M":1,1:-1)
 ; Main loop
LISTEN N $ET,$ES,RGOUT,RGSTATE,HNDLR
 S $ET="D ETRAP2^RGNETTCP",RGQUIT='$$TCPOPEN,RGOUT=""
 Q:RGQUIT
 Q:'$$STATE(1)
 S HNDLR=RGCFG("handler")_"(.RGSTATE)"
 F  Q:$$QUIT  D
 .D TCPUSE
 .D:RGMODE @HNDLR
 .D:'RGMODE WAIT
 .D TCPFLUSH
 D TCPCLOSE
 Q
 ; Wait for connection request, then spawn handler (RGMODE = 0)
WAIT N X,OK
 I RGOS D
 .X "W /WAIT(10)"
 .S OK=$P($KEY,"|")="CONNECT"
 E  D
 .R X:10
 .S OK=$T
 D:OK JOB(1,.RGCFG)
 Q
 ; Return temp global root
TMPGBL() Q $NA(^TMP("RGNETTCP",$J))
 ; Cleanup environment
CLEANUP K @$$TMPGBL,@$$LOCKNODE(.RGCFG)
 D XUTL^XUSCLEAN
 Q
 ; Returns true if listener should quit
QUIT() S:'RGQUIT RGQUIT=RGRETRY>5
 S:'RGQUIT RGQUIT=+$G(@$$LOCKNODE(.RGCFG))
 I 'RGQUIT,RGMODE=3 S RGQUIT=$$QUIT3
 Q RGQUIT
 ; Allows user to request quit in debug mode
QUIT3() N X
 U $P
 R X#1:0
 D TCPUSE
 Q X=U
 ; Save application state
STSAVE(ST) ;
 D SAVE^XUS1
 K @$$TMPGBL@(ST)
 M @$$TMPGBL@(ST)=^XUTL("XQ",$J)
 Q
 ; Restore application state
STREST(ST) ;
 K ^XUTL("XQ",$J)
 M ^XUTL("XQ",$J)=@$$TMPGBL@(ST)
 K IO
 D RESETVAR^%ZIS
 I ST,$D(IO)#2 D
 .N $ET
 .S $ET="S $EC="""" D NULLOPEN^RGNETTCP"
 .U IO
 Q
 ; Establish null device as default IO device
NULLOPEN N %ZIS,IOP,POP
 S %ZIS="0H",IOP="NULL"
 D ^%ZIS,RAISE("Failed to open null device."):POP
 U IO
 Q
 ; Open TCP listener port
 ; Returns true if successful
TCPOPEN() ;
 N POP
 S POP=0
 I RGMODE=3 D
 .I RGOS D
 ..S RGTDEV="server$"_RGCFG("port")
 ..X "O RGTDEV:(ZLISTEN=RGCFG(""port"")_"":TCP"":attach=""server""):9999:""socket"""
 ..X:$T "U RGTDEV:(nowrap:nodelimiter:ioerror=""ETRAP2^RGNETTCP"")"
 ..S POP='$T
 .E  D
 ..S RGTDEV="|TCP|"_RGCFG("port")
 ..X "O RGTDEV:(:RGCFG(""port""):""DS""):9999"
 ..S POP='$T
 E  I RGMODE D
 .S RGTDEV=$P
 .I RGOS D
 ..S @"$ZINTERRUPT=""I $$JOBEXAM^ZU($ZPOSITION)"""
 ..X "U RGTDEV:(nowrap:nodelimiter:ioerror=""ETRAP2^RGNETTCP"")"
 E  D
 .I RGOS D
 ..S @"$ZINTERRUPT=""I $$JOBEXAM^ZU($ZPOSITION)"""
 ..S RGTDEV="SCK$"_RGCFG("port")
 ..X "O RGTDEV:(zlisten=RGCFG(""port"")_"":TCP"":nowrap:nodelimiter:attach=""server""):5:""socket"""
 ..S POP='$T
 ..X:'POP "U RGTDEV W /LISTEN(5)"
 .E  D
 ..S RGTDEV="|TCP|"_RGCFG("port")
 ..X "O RGTDEV:(:RGCFG(""port""):""ADS""):5"
 ..S POP='$T
 Q 'POP
 ; Use TCP listener port
TCPUSE U RGTDEV
 Q
 ; Close TCP listener port
TCPCLOSE C:$D(RGTDEV) RGTDEV
 Q
 ; Return CNT characters from input buffer
 ; CNT = # of characters to return
 ; TMO = Optional timeout in seconds
 ; USE = If true or not specified, call TCPUSE before read
TCPREAD(CNT,TMO,USE) ;
 Q:CNT'>0 ""
 N X
 D:$G(USE,1) TCPUSE
 S TMO=+$G(TMO)
 R X#CNT:TMO
 Q X
 ; Read up to termination sequence
 ; TRM = Read termination sequence (included in returned value)
 ; TMO = Optional timeout in seconds
TCPREADT(TRM,TMO) ;
 N ST,L,X,USE
 S LN="",L=$L(TRM)-1,USE=1
 F  S X=$$TCPREAD(1,.TMO,USE) Q:'$L(X)  D  Q:L<0
 .S LN=LN_X,(TMO,USE)=0
 .S:$E(LN,$L(LN)-L,$L(LN))=TRM L=-1
 Q LN
 ; Read one byte from socket
 ; TMO = Optional timeout in seconds
TCPREADB(TMO) ;
 Q $A($$TCPREAD(1,.TMO))
 ; Write data to socket
 ; All write operations must be done via this method.
 ; This operation is buffered with a write threshold at 1024 bytes.
 ; DATA = Date to write
TCPWRITE(DATA) ;
 S RGOUT=RGOUT_DATA
 D:$L(RGOUT)>1024 TCPFLUSH
 Q
 ; Flush the output buffer
TCPFLUSH Q:'$L(RGOUT)
 D TCPUSE
 W RGOUT,!
 S RGOUT=""
 Q
 ; Write array (local or global) to TCP stream
 ; ARY  = Local or global array reference
 ; EOL  = Line terminator to add (optional)
 ; KILL = If true, kill array after writing (default is false)
ARYOUT(ARY,EOL,KILL) ;
 N ND,LN
 Q:'$L(ARY)
 S ARY=$NA(@ARY)
 S ND=ARY,LN=$QL(ARY),EOL=$G(EOL)
 F  S ND=$Q(@ND) Q:'$L(ND)  Q:$NA(@ND,LN)'=ARY  D TCPWRITE(@ND_EOL)
 K:$G(KILL) @ARY
 Q
 ; Write contents of a file to TCP stream
 ; FIL  = File path
 ; EOL  = Line terminator to add (optional)
 ; KILL = If true, delete the file after writing (default is false)
FILOUT(FIL,EOL,KILL) ;
 N LN
 S EOL=$G(EOL)
 D OPEN^RGUTOS(.FIL,"R")
 F  Q:$$READ^RGUTOS(.LN,FIL)  D TCPWRITE(LN_EOL)
 D CLOSE^RGUTOS(.FIL)
 D:$G(KILL) DELETE^RGUTOS(FIL)
 Q
 ; Throw a bad mode exception
BADMODE D RAISE("Mode not supported for OS.")
 Q
 ; Raise an exception
RAISE(MSG) ;
 D RAISE^RGUTOS(MSG)
 Q
 ; Startup error
ETRAP1 S RGQUIT=1
 D ^%ZTER,UNWIND^%ZTER
 Q
 ; Communication error
ETRAP2 S RGRETRY=RGRETRY+1
 S:RGQUIT'>0 RGQUIT=$S(RGRETRY>5:1,'RGMODE:-1,1:0)
 D:RGRETRY=1 ^%ZTER
 D UNWIND^%ZTER
 Q
 ; Lock/Unlock listener
 ; ACT:  1 = lock, 0 = unlock, missing = return status
 ; Returns true if locked, false if not.
STATE(ACT) ;
 N RES,LN
 S LN=$$LOCKNODE(.RGCFG)
 I '$D(ACT) D
 .L +@LN:0
 .S RES='$T
 .L:'RES -@LN
 E  I ACT D
 .L +@LN:1
 .S RES=$T
 E  D
 .L -@LN
 .S RES=0
 Q:$Q RES
 Q
 ; Get global reference for lock node
LOCKNODE(RGCFG) ;
 Q:'$$GETCFG(.RGCFG) ""
 Q $NA(^[RGCFG("uci")]XTMP("RGNETTCP","LN",RGCFG,$S($G(RGMODE):$J,1:0)))
 ; Change process name to reflect active listener
CHPRN(RGCFG) ;
 D SETNM^%ZOSV("RGNETTCP_"_RGCFG("port"))
 Q
