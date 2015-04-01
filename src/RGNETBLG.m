RGNETBLG ;RI/CBMI/DKM - NETSERV RPC Broker Activity Log Support ;01-Apr-2015 14:12;DKM
 ;;1.0;NETWORK SERVICES;;Jan 3, 2008;Build 144
 ;=================================================================
 ; Open a log entry.  The return value is the IEN of the new entry.
 ;   UID  = Unique session id
 ;   USER = User IEN
 ;   WID  = Workstation id
OPEN(UID,USER,WID) ;EP
 N IEN,NOW,X
 S NOW=$$NOW^XLFDT
 S:$G(WID)="" WID="UNKNOWN"
 L +^RGNET(996.56,0):2
 S X=1+$P(^RGNET(996.56,0),U,3),IEN=$O(^($C(1)),-1)+1,$P(^(0),U,3,4)=X_U_IEN,^(IEN,0)=UID_U_USER_U_WID_U_NOW_U_U_DUZ(2)
 L -^RGNET(996.56,0)
 S ^RGNET(996.56,"B",UID,IEN)=""
 S ^RGNET(996.56,"BUSER",USER,IEN)=""
 S ^RGNET(996.56,"BWID",WID,IEN)=""
 S ^RGNET(996.56,"BLOGIN",NOW,IEN)=""
 S ^RGNET(996.56,"BDIV",DUZ(2),IEN)=""
 Q IEN
 ; Close a log entry.
 ;  IEN = IEN of the entry.
CLOSE(IEN) ;EP
 N NOW
 S NOW=$$NOW^XLFDT
 S:$D(^RGNET(996.56,+IEN,0)) $P(^(0),U,5)=NOW,^RGNET(996.56,"BLOGOUT",NOW,IEN)=""
 Q
 ; Log an activity
 ;  IEN  = IEN of log entry
 ;  TYPE = Type of log entry (1=RPC, 2=Event)
 ;  NAME = Text name associated with activity
 ;  Returns subfile IEN
LOG(IEN,TYPE,NAME) ;EP
 N SUB,NOW
 Q:'$D(^RGNET(996.56,IEN)) 0
 S NOW=$$NOW^XLFDT
 S SUB=$O(^RGNET(996.56,IEN,10,$C(1)),-1)+1,^(0)="^996.561D^"_SUB_U_SUB,^(SUB,0)=NOW_U_TYPE_U_NAME
 Q SUB
 ; Add an entry to the specified activity
 ;  IEN = IEN of log entry
 ;  SUB = IEN of subfile entry
 ;  ARY = Array or global root
 ;  INC = Include variable name with output (optional)
ADD(IEN,SUB,ARY,INC) ;EP
 N ROOT,WP,A,L,P,X,Y,Z
 S ROOT=$NA(^RGNET(996.56,IEN,10,SUB,10))
 S WP=$O(@ROOT@($C(1)),-1),WP(0)=WP,INC=+$G(INC),(A,ARY)=$NA(@ARY),L=$QL(ARY)
 F  D:$D(@A)#2  S A=$Q(@A) Q:'$L(A)  Q:$NA(@A,L)'=ARY
 .S X=@A,P=$S(INC:A_" = ",1:"")
 .F  Q:'$L(X)  D
 ..S Y=$F(X,$C(13))
 ..S:'Y!(Y>200) Y=200
 ..S Z=$TR($E(X,1,Y-1),$C(13,10)),X=$E(X,Y,999999)
 ..S WP=WP+1,@ROOT@(WP,0)=P_Z,P=$S(INC:">>> ",1:"")
 S:WP'=WP(0) @ROOT@(0)="^^"_WP_U_WP_U_$$NOW^XLFDT
 Q
 ; Delete a log entry
DELETE(DA) ;
 Q:'$D(^RGNET(996.56,DA))
 N DIK
 S DIK="^RGNET(996.56,"
 D ^DIK
 Q
 ; Task purge in background
TASKPRG N ZTSK
 S ZTSK=$$QUEUE^RGUTSK("DOPURGE^RGNETBLG","Purge RG ACTIVITY LOG")
 I ZTSK>0 W !,"RG ACTIVITY LOG purge submitted as task #",ZTSK,!!
 E  W !,"Error submitting RG ACTIVITY LOG purge.",!!
 Q
 ; Purge log entries according to retention criteria
DOPURGE N DAYS,LP,IEN
 S DAYS=$$GET^XPAR("ALL","RGNETB ACTIVITY RETENTION")
 Q:'DAYS
 S LP=$$FMADD^XLFDT(DT,-DAYS)
 F  S LP=$O(^RGNET(996.56,"BLOGIN",LP),-1) Q:'LP  D
 .S IEN=0
 .F  S IEN=$O(^RGNET(996.56,"BLOGIN",LP,IEN)) Q:'IEN  D
 ..D DELETE(IEN)
 Q
 ; Returns true if activity logging is active
 ; Creates a log entry if one does not already exist
ISACTIVE() ;
 N RTN,DUZ2
 Q:'$D(RGNETB("UID")) 0
 Q:'RGNETB("UID") 0
 S DUZ2=$$GETVAR^RGNETBUT("DUZ2")
 S RTN=$$GETVAR^RGNETBUT("ALOG"_$S(DUZ2:":"_DUZ2,1:""))
 I RTN="" D
 .S RTN=+$$GET^XPAR("ALL","RGNETB ACTIVITY LOGGING","`"_$$GETVAR^RGNETBUT("AID0"))
 .S:RTN RTN=$$OPEN(RGNETB("UID"),DUZ,$$GETVAR^RGNETBUT("WID"))
 .D SETVAR^RGNETBUT("ALOG"_$S(DUZ2:":"_DUZ2,1:""),RTN)
 Q RTN
