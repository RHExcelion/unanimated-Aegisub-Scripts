-- Hyperdimensional Relocator offers a plethora of functions, focusing primarily on \pos, \move, \org, \clip, and rotations.
-- Check Help (Space Travel Guide) for detailed description of all functions.

script_name="Hyperdimensional Relocator"
script_description="Advanced metamorphosis of multidimensional coordinates."
script_author="reanimated"
script_url="http://unanimated.xtreemhost.com/ts/relocator.lua"
script_version="4.0"
script_namespace="ua.Relocator"

local haveDepCtrl,DependencyControl,depRec=pcall(require,"l0.DependencyControl")
if haveDepCtrl then
  script_version="4.0.0"
  depRec=DependencyControl{feed="https://raw.githubusercontent.com/TypesettingTools/unanimated-Aegisub-Scripts/master/DependencyControl.json"}
end

re=require'aegisub.re'

function positron(subs,sel)
	ps=res.post
	shake={} shaker={}
	count=0
	nsel={} for z,i in ipairs(sel) do table.insert(nsel,i) end
    if res.posi:match("fbf X") then
	XYtab={}
	for z,i in ipairs(sel) do
		line=subs[i]
		text=line.text
		local X,Y=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		table.insert(XYtab,{x=X,y=Y})
	end
	if res.first then Xref=XYtab[1].x Yref=XYtab[1].y else Xref=XYtab[#XYtab].x Yref=XYtab[#XYtab].y end
    end
	
    -- Replicate GUI
    if res.posi=="replicate" then
	rplGUI={
	{x=0,y=0,width=2,class="label",label="Replicas:"},
	{x=2,y=0,width=3,class="intedit",name="rep",value=repl or 3,min=1,hint="replicas to create"},
	{x=0,y=1,width=3,class="label",label="Distances for:"},
	{x=3,y=1,width=1,class="dropdown",name="dtype",items={"one replica","last replica"},value="last replica"},
	{x=4,y=1,width=2,class="label",label="  last replica"},
	{x=6,y=1,width=2,class="label",label="formation curve"},
	{x=0,y=2,width=2,class="label",label="X Distance:"},
	{x=0,y=3,width=2,class="label",label="Y Distance:"},
	{x=2,y=2,width=2,class="floatedit",name="xdist",value=xdist or 0},
	{x=2,y=3,width=2,class="floatedit",name="ydist",value=ydist or 0},
	{x=4,y=2,width=2,class="dropdown",name="xar",items={"absolute","relative"},value="relative",hint="distance type for 'last replica'"},
	{x=4,y=3,width=2,class="dropdown",name="yar",items={"absolute","relative"},value="relative",hint="distance type for 'last replica'"},
	{x=6,y=2,width=2,class="floatedit",name="xcel",value=xcel or 1,min=0,hint="acceleration for 'last replica'"},
	{x=6,y=3,width=2,class="floatedit",name="ycel",value=ycel or 1,min=0,hint="acceleration for 'last replica'"},
	{x=0,y=4,width=6,class="checkbox",name="mov",label="use \\move for last replica coordinates"},
	{x=0,y=5,width=2,class="checkbox",name="delay",label="Delay:"},
	{x=2,y=5,width=3,class="intedit",name="del",value=0,min=0},
	{x=5,y=5,width=1,class="label",label="frames"},
	{x=6,y=5,width=2,class="checkbox",name="keepend",label="keep end",hint="try to keep end time\nsame as original if possible"},
	}
	lucid={x=0,y=6,width=8,height=8,class="textbox",value=replika}
	repeat
	if reprez then
	  for k,v in ipairs(rplGUI) do
	    if v.name then v.value=reprez[v.name] end
	  end
	end
	btns={"Replicate","Elucidate","Disintegrate"}
	if pres=="Elucidate" then table.insert(rplGUI,lucid) table.remove(btns,2) end
	pres,rez=ADD(rplGUI,btns,{ok='Replicate',close='Disintegrate'})
	reprez=rez
	until pres~="Elucidate"
	if pres=="Disintegrate" then ak() end
	repl=rez.rep+1
	xcel=rez.xcel if xcel==0 then xcel=1 end
	ycel=rez.ycel if ycel==0 then ycel=1 end
	if rez.mov then moverep=true else moverep=false end
	if rez.dtype=="one replica" and not moverep then dtype=1 xcel=1 ycel=1 else dtype=0 end
	if rez.xar=="absolute" then xabs=true else xabs=false end
	if rez.yar=="absolute" then yabs=true else yabs=false end
	xdist=rez.xdist ydist=rez.ydist
	if rez.delay then replay=rez.del else replay=0 end
	if rez.keepend then endrep=true else endrep=false end
    end
	
    -- FBF Retrack Data Gathering
    if res.posi=="fbf retrack" then
	if #sel<3 then t_error("Error: You must select at least 3 lines for 'fbf retrack'.",1) end
	retrack={} truck="" posref={}
	posx1,posy1=subs[sel[1]].text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		if not posx1 then t_error("Error: Missing \\pos in the first line.",1) end
	posxl,posyl=subs[sel[#sel]].text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		if not posxl then t_error("Error: Missing \\pos in the last line.",1) end
	-- retrack tab
	for z,i in ipairs(sel) do
		l=subs[i] fr1=ms2fr(l.start_time)
		if not truck:match("|"..fr1.."|") then table.insert(retrack,fr1) truck=truck.."|"..fr1.."|" end
	end
	table.sort(retrack)
	-- posref tab
	if res.smo then
	    for z,i in ipairs(sel) do
		l=subs[i] frame=ms2fr(l.start_time)
		fpos,total=detrack(z,sel,retrack,frame)
		posix,posiy=l.text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		if not posix then t_error("Error: Missing \\pos in line "..z..".",1) end
		if not posref[fpos] then posref[fpos]={x=posix,y=posiy} end
	    end
	end
	if res.layers and #retrack==1 then t_error("Error: All lines start on the same frame.\nIf you want to change position of signs\non the same frame, uncheck layers.",1) end
	if res.layers then total=#retrack else total=#sel end
	xstep=round((posxl-posx1)/(total-1),2)
	ystep=round((posyl-posy1)/(total-1),2)
	if ps<=0 then ps=1 end
	if res.eks>0 then acx=res.eks else acx=ps end
	if res.wai>0 then acx=res.wai else acy=ps end
    end
    
    -- Positron Cannon Lines --
    if res.posi=="space out letters" then table.sort(sel,function(a,b) return a>b end) end
    for z,i in ipairs(sel) do
	progress("Depositing line: "..z.."/"..#sel)
	line=subs[i]
	text=line.text
	nontra=text:gsub("\\t%b()","")
	
	-- Align X
	if res.posi=="Align X" then
	    if z==1 and not text:match("\\pos") then t_error("Missing \\pos tag.",1) end
	    if z==1 and res.first then pxx=text:match("\\pos%(([%d%.%-]+),") ps=pxx end
	    text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)","\\pos("..ps..",%2)")
	end
	
	-- Align Y
	if res.posi=="Align Y" then
	    if z==1 and not text:match("\\pos") then t_error("Missing \\pos tag.",1) end
	    if z==1 and res.first then pyy=text:match("\\pos%([%d%.%-]+,([%d%.%-]+)") ps=pyy end
	    text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)","\\pos(%1,"..ps..")")
	end
	
	-- Mirrors
	if res.posi:match"mirror" then
	    if not text:match("\\pos") and not text:match("\\move") then t_error("Fail. Some lines are missing \\pos.",1) end
	    info(subs)
	    if not text:match("^{[^}]-\\an%d") then sr=stylechk(subs,line.style) 
		text=text:gsub("^","{\\an"..sr.align.."}") :gsub("({\\an%d)}{\\","%1\\")
	    end
	    if ps and ps~=0 then resx=2*ps resy=2*ps end
	    if res.posi=="horizontal mirror" then
	    mirs={"1","4","7","9","6","3"}
	    text2=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(x,y) return "\\pos("..resx-x..","..y..")" end)
	    :gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(x,y,x2,y2) return "\\move("..resx-x..","..y..","..resx-x2..","..y2 end)
	    :gsub("\\an([147369])",function(a) for m=1,6 do if a==mirs[m] then b=mirs[7-m] end end return "\\an"..b end)
	    	if res.rota then
		    if not text2:match("^{[^}]-\\fry") then text2=addtag("\\fry0",text2) end text2=flip("fry",text2)
		end
	    else
	    mirs={"1","2","3","9","8","7"}
	    text2=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(x,y) return "\\pos("..x..","..resy-y..")" end)
	    :gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(x,y,x2,y2) return "\\move("..x..","..resy-y..","..x2..","..resy-y2 end)
	    :gsub("\\an([123789])",function(a) for m=1,6 do if a==mirs[m] then b=mirs[7-m] end end return "\\an"..b end)
	    	if res.rota then
		    if not text2:match("^{[^}]-\\frx") then text2=addtag("\\frx0",text2) end text2=flip("frx",text2)
		end
	    end
	    l2=line	l2.text=text2
	    if res.keep then
	      subs.insert(i+1,l2)
	      for i=z,#sel do sel[i]=sel[i]+1 end
	    else
	      text=text2
	    end
	end
	
	-- org to fax
	if res.posi=="org to fax" then
	    if text:match("\\move") then t_error("What's \\move doing there??",1) end
	    if not text:match("\\pos") then text=getpos(subs,text) end
	    if not text:match("\\org") then t_error("Missing \\org.",1) end
	    pox,poy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)")
	    orx,ory=text:match("\\org%(([%d%.%-]+),([%d%.%-]+)")
	    sr=stylechk(subs,line.style)
	    nontra=text:gsub("\\t%b()","")
	    rota=nontra:match("\\frz([%d%.%-]+)") or sr.angle
	    scx=nontra:match("\\fscx([%d%.]+)") or sr.scale_x
	    scy=nontra:match("\\fscy([%d%.]+)") or sr.scale_y
	    scr=scx/scy
	    ad=pox-orx
	    op=poy-ory
	    tang=(ad/op)
	    ang1=math.deg(math.atan(tang))
	    ang2=ang1-rota
	    tangf=math.tan(math.rad(ang2))
	    
	    faks=round(tangf/scr,2)
	    text=addtag3("\\fax"..faks,text)
	    text=text:gsub("\\org%([^%)]+%)","")
	    :gsub(ATAG,function(tg) return duplikill(tg) end)
	end
	
	-- clip to fax
	if res.posi=="clip to fax" then
	    if not text:match("\\clip%(m") then t_error("Missing \\clip.",1) end
	    cx1,cy1,cx2,cy2,cx3,cy3,cx4,cy4=text:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+)")
	    if cx1==nil then cx1,cy1,cx2,cy2=text:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+)") end
	    sr=stylechk(subs,line.style)
	    nontra=text:gsub("\\t%b()","")
	    rota=nontra:match("\\frz([%d%.%-]+)") or sr.angle
	    scx=nontra:match("\\fscx([%d%.]+)") or sr.scale_x
	    scy=nontra:match("\\fscy([%d%.]+)") or sr.scale_y
	    scr=scx/scy
	    ad=cx1-cx2
	    op=cy1-cy2
	    tang=(ad/op)
	    ang1=math.deg(math.atan(tang))
	    ang2=ang1-rota
	    tangf=math.tan(math.rad(ang2))
	    
	    faks=round(tangf/scr,2)
	    text=addtag3("\\fax"..faks,text)
	    if cy4 then
		tang2=((cx3-cx4)/(cy3-cy4))
		ang3=math.deg(math.atan(tang2))
		ang4=ang3-rota
		tangf2=math.tan(math.rad(ang4))
		faks2=round(tangf2,2)
		endcom=""
		repeat text=text:gsub("({[^}]-})%s*$",function(ec) endcom=ec..endcom return "" end)
		until not text:match("}$")
		text=text:gsub("(.)$","{\\fax"..faks2.."}%1")
		
		vis=text:gsub("%b{}","")
		orig=text:gsub(STAG,"")
		tg=text:match(STAG)
		chars={}
		for char in vis:gmatch(".") do table.insert(chars,char) end
		faxdiff=(faks2-faks)/(#chars-1)
		tt=chars[1]
		for c=2,#chars do
		    if c==#chars then ast="" else ast="*" end
		    if chars[c]==" " then tt=tt.." " else
		    tt=tt.."{"..ast.."\\fax"..round((faks+faxdiff*(c-1)),2) .."}"..chars[c]
		    end
		end
		text=tg..tt
		if orig:match("{%*?\\") then text=textmod(orig,text) end
		
		text=text..endcom
	    end
	    text=text:gsub("\\clip%b()","")
	    :gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}")
	    :gsub(ATAG,function(tg) return duplikill(tg) end)
	    :gsub("%**}","}")
	end
	
	-- clip to frz
	if res.posi=="clip to frz" then
	    if not text:match("\\clip%(m") then t_error("Missing \\clip.",1) end
	    cx1,cy1,cx2,cy2,cx3,cy3,cx4,cy4=text:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+)")
	    if cx1==nil then cx1,cy1,cx2,cy2=text:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+)") end
	    ad=cx2-cx1
	    op=cy1-cy2
	    tang=(op/ad)
	    ang1=math.deg(math.atan(tang))
	    rota=round(ang1,2)
	    if ad<0 then rota=rota-180 end
	    
	    if cy4 then
		ad2=cx4-cx3
		op2=cy3-cy4
		tang2=(op2/ad2)
		ang2=math.deg(math.atan(tang2))
		rota2=round(ang2,2)
		if ad2<0 then rota2=rota2-180 end
	    else rota2=rota
	    end
	    rota3=(rota+rota2)/2
	    
	    text=addtag("\\frz"..rota3,text)
	    text=text:gsub("\\clip%b()","")
	    :gsub(ATAG,function(tg) return duplikill(tg) end)
	end
	
	-- clip to reposition
	if res.posi=="clip to reposition" then
	    if not text:match("\\clip%(m") then t_error("Missing \\clip.",1) end
	    cx1,cy1,cx2,cy2=text:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+)")
	    repo1=cx2-cx1 repo2=cy2-cy1
	    text=text:gsub("\\clip%b()","")
	    :gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)",function(x,y) return "\\pos("..round(x+repo1,2)..","..round(y+repo2,2) end)
	end
	
	-- shake
	if res.posi=="shake" then
	    if text:match("\\move") then t_error("What's \\move doing there??",1) end
	    if not text:match("\\pos") then text=getpos(subs,text) end
	    s=line.start_time
	    diam=res.post
	    scal=res.force
	    if diam==0 and not res.sca then diamx=res.eks diamy=res.wai else diamx=diam diamy=diam end
	    shx=math.random(-100,100)/100*diamx	if res.smo and lshx then shx=(shx+3*lshx)/4 end
	    shy=math.random(-100,100)/100*diamy	if res.smo and lshy then shy=(shy+3*lshy)/4 end
	    shr=math.random(-100,100)/100*diam	if res.smo and lshr then shr=(shr+3*lshr)/4 end
	    shsx=math.random(-100,100)/100*scal	if res.smo and lshsx then shsx=(shsx+3*lshsx)/4 end
	    shsy=math.random(-100,100)/100*scal	if res.smo and lshsy then shsy=(shsy+3*lshsy)/4 end
	    if res.layers then
		ch=0
		for p=1,#shake do sv=shake[p]
		  if sv[1]==s then ch=1 shx=sv[2] shy=sv[3] shr=sv[4] shsx=sv[5] shsy=sv[6] end
		end
		if ch==0 then
		  a={s,shx,shy,shr,shsx,shsy}
		  table.insert(shake,a)
		end
	    end
	    	lshx=shx	lshy=shy	lshr=shr	lshsx=shsx	lshsy=shsy
	    text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(x,y) return "\\pos("..x+shx..","..y+shy..")" end)
	    if res.rota then
		text=text:gsub("\\frz([%d%.%-]+)",function(z) return "\\frz"..z+shr end)
		if not text:match("^{[^}]-\\frz") then text=addtag("\\frz"..shr,text) end
	    end
	    if res.sca then
		text=text:gsub("(\\fscx)([%d%.%-]+)",function(x,y) return x..y+shsx end)
		text=text:gsub("(\\fscy)([%d%.%-]+)",function(x,y) return x..y+shsy end)
		if not nontra:match("^{[^}]-\\fscx") then text=addtag3("\\fscx"..shsx+100,text) end
		if not nontra:match("^{[^}]-\\fscy") then text=addtag3("\\fscy"..shsy+100,text) end
	    end
	    text=text:gsub("([%d%.%-]+%d)([\\}%),])",function(a,b) return round(a,2)..b end)
	end
	
	-- shake rotation
	if res.posi=="shake rotation" then
	    s=line.start_time
	    ang=ps
	    angx=res.eks
	    angy=res.wai
	    angl={ang,angx,angy}
	    rots={"\\frz","\\frx","\\fry"}
	    for r=1,3 do ro=rots[r] an=angl[r]
	    if an~=0 then
	      shr=math.random(-100,100)/100*an
	      if res.layers then
		ch=0
		for p=1,#shaker do sv=shaker[p]
		  if sv[1]==s and sv[2]==r then ch=1 shr=sv[3] end
		end
		if ch==0 then rt=r
		  a={s,rt,shr}
		  table.insert(shaker,a)
		end
	      end
	      text=text:gsub(ro.."([%d%.%-]+)",function(z) return ro..z+shr end)
	      text=addtag3(ro..shr,text)
	    end end
	end
	
	-- shadow layer
	if res.posi=="shadow layer" then
		sr=stylechk(subs,line.style)
		text=text:gsub("\\1c","\\c")
		shadcol=nontra:match("^{[^}]-\\4c(&H%x+&)") or sr.color4:gsub("H%x%x","H")
		if ps~=0 then xsh=ps ysh=ps else xsh=res.eks ysh=res.wai end
		if xsh==0 and ysh==0 then
		  xs=nontra:match("^{[^}]-\\xshad([%d%.%-]+)") or nontra:match("^{[^}]-\\shad([%d%.]+)") or sr.shadow
		  ys=nontra:match("^{[^}]-\\yshad([%d%.%-]+)") or nontra:match("^{[^}]-\\shad([%d%.]+)") or sr.shadow
		else xs=xsh ys=ysh
		end
		
	    if tonumber(xs)>0 and tonumber(ys)>0 then
		text=text:gsub("\\t(%b())",function(t) return "\\tra"..t:gsub("\\","/") end)
		if not text:match("\\pos") and not text:match("\\move") then text=getpos(subs,text) end
		text=text:gsub("\\[xy]?shad([%d%.%-]+)","")
		l2=line	text2=text
		
		text2=text2
		:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) return "\\pos("..a+xs..","..b+ys..")" end)
		:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		function(a,b,c,d) return "\\pos("..a+xs..","..b+ys..","..c+xs..","..d+ys end)
		:gsub(ATAG,function(tag)
			if tag:match("\\4c&H%x+&") then
			  tag=tag:gsub("\\3?c&H%x+&","") :gsub("\\4c(&H%x+&)","\\c%1\\3c%1")
			else tag=tag:gsub("\\3?c&H%x+&","")
			end
			if tag:match("\\4a&H%x+&") then
			  tag=tag:gsub("\\alpha&H%x+&","") :gsub("\\4a(&H%x+&)","\\alpha%1")
			end
			tag=tag:gsub("\\[13]a&H%x+&","") :gsub("{}","")
			return tag
		end)
		
		text2=addtag3("\\c"..shadcol,text2)
		text2=addtag3("\\3c"..shadcol,text2)
		text=text:gsub("\\tra(%b())",function(t) return "\\t"..t:gsub("/","\\") end)
		
		l2.text=text2
		subs.insert(i+1,l2)
		line.layer=line.layer+1
		sel=shiftsel(sel,i,0) nsel=shiftsel(nsel,i,1)
	    end
	    if z==#sel then sel=nsel end
	end

	-- fbf X <--> Y
	if res.posi=="fbf X <--> Y" then
	  newY=XYtab[z].x-Xref+Yref	if res.rota then newY=Yref-(XYtab[z].x-Xref) end
	  newX=XYtab[z].y-Yref+Xref	if res.rota then newX=Xref-(XYtab[z].y-Yref) end
	  text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)","\\pos("..newX..","..newY..")")
	end

	-- Space out letters
	if res.posi=="space out letters" then
	    sr=stylechk(subs,line.style)
	    acalign=nil
	    text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),.-%)","\\pos(%1,%2)") :gsub("%s?\\[Nn]%s?"," ")
	    if not text:match"\\pos" then text=getpos(subs,text) end
	    tags=text:match(STAG) or ""
	    after=text:gsub(STAG,"") :gsub("{[^\\}]-}","")
	    local px,py=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
	    local x1,width,w,wtotal,let,spacing,avgspac,ltrspac,xpos,lastxpos,spaces,prevlet,scx,k1,k2,k3,bord,off,inwidth,wdiff,pp,tpos
	    scx=text:match("\\fscx([%d%.]+)") or sr.scale_x
	    k1,k2,k3=text:match("clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),")
	    bord=text:match("^{[^}]-\\bord([%d%.]+)") or sr.outline
	    visible=text:gsub("%b{}","")
	    letters={}    wtotal=0
	    	letrz=re.find(visible,".")
		  for l=1,#letrz do
		    w=aegisub.text_extents(sr,letrz[l].str)
		    table.insert(letters,{l=letrz[l].str,w=w})
		    wtotal=wtotal+w
		  end
	    intags={}    cnt=0
		for chars,tag in after:gmatch("([^}]+)({\\[^}]+})") do
		    pp=re.find(chars,".")
		    tpos=#pp+1+cnt
		    intags[tpos]=tag
		    cnt=cnt+#pp
		end
	    spacing=ps
	    avgspac=wtotal/#letters
	    off=(letters[1].w-letters[#letters].w)/4*scx/100
	    inwidth=(wtotal-letters[1].w/2-letters[#letters].w/2)*scx/100
	    if spacing==1 then spacing=round(avgspac*scx)/100 end
	    width=(#letters-1)*spacing	--off
	    
	    -- klip-based stuff
	    if k1 then 
		width=(k3-k1)-letters[1].w/2*(scx/100)-letters[#letters].w/2*(scx/100)-(2*bord)
		spacing=(width+2*bord)/(#letters-1)
		px=(k1+k3)/2-off
		tags=tags:gsub("\\i?clip%b()","")
	    end
	    
	    -- find starting x point based on alignment
	    if not acalign then acalign=text:match("\\an(%d)") or sr.align end
	    acalign=tostring(acalign)
	    if acalign:match("[147]") then
		tags=tags:gsub("\\an%d","") :gsub("^{","{\\an"..acalign+1)
		:gsub("\\pos%(([%d%.%-]+)",function(p) return "\\pos("..round(p+(wtotal/2)*(scx/100),2) end)
	    end
	    if acalign:match("[369]") then
		tags=tags:gsub("\\an%d","") :gsub("^{","{\\an"..acalign-1)
		:gsub("\\pos%(([%d%.%-]+)",function(p) return "\\pos("..round(p-(wtotal/2)*(scx/100),2) end)
	    end
	    if not k1 then px,py=tags:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)") end
	    acalign=tags:match("\\an(%d)")
	    x1=round(px-width/2)
	    
	    wdiff=(width-inwidth)/(#letters-1)
	    lastxpos=x1
	    spaces=0
	    -- weird letter-width sorcery starts here
	    for t=1,#letters do
		let=letters[t]
		if t>1 then
		  prevlet=letters[t-1]
		  ltrspac=(let.w+prevlet.w)/2*scx/100+wdiff
		  ltrspac=round(ltrspac,2)
		else
		  fact1=spacing/(avgspac*scx/100)
		  fact2=(let.w-letters[#letters].w)/4*scx/100
		  ltrspac=round(fact1*fact2,2)
		end
		if intags[t] then tags=tags..intags[t] tags=tags:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") tags=duplikill(tags) end
		t2=tags..let.l
		xpos=lastxpos+ltrspac
		t2=t2:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)","\\pos("..xpos..",%2)")
		lastxpos=xpos
		l2=line
		l2.text=t2
		if t==1 then text=t2 else
		if let.l~=" " then subs.insert(i+t-1-spaces,l2) else count=count-1 spaces=spaces+1 end
		end
	    end
	    count=count+#letters-1
	end
	
	-- Replicate
	if res.posi=="replicate" then
	  startf=ms2fr(line.start_time)
	  endf=ms2fr(line.end_time)
	  if moverep then
		x1,y1,mx,my=text:match("\\move%(([^,]+),([^,]+),([^,]+),([^,%)]+)")
		if not mx then t_error("Abort: No \\move tag on line "..z,1) end
		rxdist=mx rydist=my
		text=text:gsub("\\move%b()","\\pos("..x1..","..y1..")")
	  else
		if not text:match("\\pos") and not text:match("\\move") then text=getpos(subs,text) end
		x1,y1=text:match("\\pos%(([^,]+),([^,]+)%)")
		if not x1 then x1,y1=text:match("\\move%(([^,]+),([^,]+),") end
		if dtype==1 then rxdist=xdist*(repl-1)+x1 rydist=ydist*(repl-1)+y1
		else
			if xabs then rxdist=xdist else rxdist=xdist+x1 end
			if yabs then rydist=ydist else rydist=ydist+y1 end
		end
	  end
	  -- replicating
	  for r=repl,1,-1 do
		l2=line
		posx=numgrad(x1,rxdist,repl,r,xcel)
		posy=numgrad(y1,rydist,repl,r,ycel)
		text2=text:gsub("\\pos%b()","\\pos("..posx..","..posy..")")
		:gsub("\\move%(([^,]+),([^,]+),([^,]+),([^,%)]+)",function(m1,m2,m3,m4)
			return "\\move("..posx..","..posy..","..m3-m1+posx..","..m4-m2+posy end)
		startf2=startf+replay*(r-1)
		start2=fr2ms(startf2) end2=fr2ms(endf)
		if endrep then if endf<startf2 then end2=fr2ms(startf2+1) end -- keep end or start+1
		else end2=fr2ms(endf+replay*(r-1)) end
		l2.start_time=start2 l2.end_time=end2
		l2.text=text2
		if r==1 then line=l2 else subs.insert(i+1,l2) sel=shiftsel(sel,i,0) nsel=shiftsel(nsel,i,1) end
	  end
	  line.start_time=fr2ms(startf)
	  line.end_time=fr2ms(endf)
	  if z==#sel then sel=nsel end
	end
	
	-- FBF Retrack
	if res.posi=="fbf retrack" then
	frame=ms2fr(line.start_time)
	fpos,total=detrack(z,sel,retrack,frame)
	if not text:match("\\pos") then text=getpos(text) end
	posix,posiy=text:match("\\pos%(([^,]+),([^,]+)%)")
	  if fpos>1 and fpos<total then
	    if res.smo then
		-- smoothen track
		smf=math.abs(res.force)/100
		if smf>1 then smf=1 end
		if smf<0 then smf=0 end
		ref=round(math.abs(ps))
		if ref<1 then ref=1 end
		for re=1,ref do
		    sm=smf*(1/re)
		    if re<fpos and re<total-fpos+1 then
			xref=(posref[fpos-re].x+posref[fpos+re].x)/2
			yref=(posref[fpos-re].y+posref[fpos+re].y)/2
			diffx=round(posix-xref,2)
			diffy=round(posiy-yref,2)
			newdiffx=diffx*sm
			newdiffy=diffy*sm
			newx=round(posix-newdiffx,2)
			newy=round(posiy-newdiffy,2)
			posix=newx posiy=newy
			posref[fpos]={x=newx,y=newy}
		    end
		end
	    else
		-- regular fbf transform
		newx=numgrad(posx1,posxl,total,fpos,acx)
		newy=numgrad(posy1,posyl,total,fpos,acy)
	    end
	  text=text:gsub("\\pos%b()","\\pos("..newx..","..newy..")")
	  end
	end

	line.text=text
        subs[i]=line
    end
    table.sort(sel)
    if res.posi=="space out letters" then last=sel[#sel] for s=1,count do table.insert(sel,last+s) end end
    return sel
end

function bilocator(subs,sel)
    xx=res.eks	yy=res.wai  rM=res.move
    if rM=="transmove" and sel[#sel]==#subs then table.remove(sel,#sel) end
    for z=#sel,1,-1 do
        i=sel[z]
	progress("Moving through hyperspace... "..(#sel-z+1).."/"..#sel)
	line=subs[i]
	text=line.text
	start=line.start_time
	endt=line.end_time

	if rM=="transmove" and i<#subs then
	
		nextline=subs[i+1]
		text2=nextline.text
		text=text:gsub("\\1c","\\c")
		text2=text2:gsub("\\1c","\\c")
		movt1,movt2=gettimes(start,endt)
		if res.times then movt=","..movt1..","..movt2 else movt="" end
		
		-- move
		p1=text:match("\\pos%((.-)%)")
		p2=text2:match("\\pos%((.-)%)")
		if p1==nil or p2==nil then t_error("Missing \\pos tag(s).",1) end
		if p2~=p1 then text=text:gsub("\\pos%((.-)%)","\\move(%1,"..p2..movt..")") end
		
		-- transforms
		tf=""
		
		tftags={"fs","fsp","fscx","fscy","blur","bord","shad","fax","fay"}
		for tg=1,#tftags do
		  t=tftags[tg]
		  if text2:match("\\"..t.."[%d%.%-]+") then tag2=text2:match("(\\"..t.."[%d%.%-]+)")
		    if text:match("\\"..t.."[%d%.%-]+") then tag1=text:match("(\\"..t.."[%d%.%-]+)") else tag1="" end
		    if tag1~=tag2 then tf=tf..tag2 end
		  end
		end
		
		tfctags={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
		for tg=1,#tfctags do
		  t=tfctags[tg]
		  if text2:match("\\"..t.."&H%x+&") then tag2=text2:match("(\\"..t.."&H%x+&)")
		    if text:match("\\"..t.."&H%x+&") then tag1=text:match("(\\"..t.."&H%x+&)") else tag1="" end
		    if tag1~=tag2 then tf=tf..tag2 end
		  end
		end
		
		tfrtags={"frz","frx","fry"}
		for tg=1,#tfrtags do
		  t=tfrtags[tg]
		  if text2:match("\\"..t.."[%d%.%-]+") then
		    tag2=text2:match("(\\"..t.."[%d%.%-]+)") rr2=tonumber(text2:match("\\"..t.."([%d%.%-]+)"))
		    if text:match("\\"..t.."[%d%.%-]+") then
		        tag1=text:match("(\\"..t.."[%d%.%-]+)") rr1=tonumber(text:match("\\"..t.."([%d%.%-]+)"))
		    else tag1="" rr1=0 end
		    if tag1~=tag2 then
			if res.rotac and math.abs(rr2-rr1)>180 then
			  if rr2>rr1 then rr2=rr2-360 tag2="\\frz"..rr2 else
			  rr1=rr1-360 text=text:gsub("\\frz[%d%.%-]+","\\frz"..rr1)
			  end
			end
		    tf=tf..tag2 end
		  end
		end
		
		-- apply transform
		if tf~="" then text=text:gsub("^({\\[^}]-)}","%1\\t("..movt:gsub("^,(.*)","%1,")..tf..")}") end
		
		-- delete line 2
		if res.keep==false then subs.delete(i+1)
		  if i<#sel then
		    for s=i+1,#sel do sel[s]=sel[s]-1 end
		  end
		end
		
	end -- end of transmove

	if rM=="horizontal" then text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)","\\move(%1,%2,%3,%2") end
	if rM=="vertical" then text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)","\\move(%1,%2,%1,%4") end
	if rM=="rvrs. move" then text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)","\\move(%3,%4,%1,%2") end

	if rM=="clip2move" then
		movt1,movt2=gettimes(start,endt)
		if res.times then M=","..movt1..","..movt2 else M="" end
		if not text:match("\\clip") then t_error("Missing \\clip.",true) end
		cx1,cy1,cx2,cy2=text:match("\\clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+)")
		xmov=cx2-cx1 ymov=cy2-cy1
		text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)[^%)]*",function(x,y)
			return "\\move("..x..","..y..","..round(x+xmov,2)..","..round(y+ymov,2)..M end)
		:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)",function(x,y)
			return "\\move("..x..","..y..","..round(x+xmov,2)..","..round(y+ymov,2)..M end)
		:gsub("\\clip%b()","")
	end

	if rM=="shiftstart" then
		text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)([^%)]*)",function(a,b,c,d,e)
			if res.videofr then vfcheck() e=e:gsub("([%d%.%-]+)(,[%d%.%-]+)",videopos.."%2") end
			return "\\move("..a+xx..","..b+yy..","..c..","..d..e end)
	end

	if rM=="shiftmove" or rM=="move to" then
		movt1,movt2=gettimes(start,endt)
		if res.videofr then vfcheck() end
		if res.times or res.videofr then M=","..movt1..","..movt2 else M="" end
		text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)([^%)]*)",function(a,b,c,d,e)
			if res.videofr then if e~="" then M=e end M=M:gsub("([%d%.%-]+,)([%d%.%-]+)","%1"..videopos) end
			if rM=="move to" then c=xx d=yy else c=c+xx d=d+yy end
			return "\\move("..a..","..b..","..c..","..d..M end)
		text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)",function(a,b)
			if res.videofr then M=M:gsub("([%d%.%-]+,)([%d%.%-]+)","%1"..videopos) end
			if rM=="move to" then c=xx d=yy else c=a+xx d=b+yy end
			return "\\move("..a..","..b..","..c..","..d..M end)
	end

	if rM=="move clip" then
		m1,m2,m3,m4=text:match("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
		mt=text:match("\\move%([^,]+,[^,]+,[^,]+,[^,]+,([%d%.,%-]+)")
		if mt==nil then mt="" else mt=mt.."," end
		klip=text:match("\\i?clip%([%d%.,%-]+%)")
		klip=klip:gsub("(\\i?clip%()([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
		function(a,b,c,d,e) return a..b+m3-m1..","..c+m4-m2..","..d+m3-m1..","..e+m4-m2 end)
		text=addtag("\\t("..mt..klip..")",text)
	end

	text=roundpar(text,2)
	line.text=text
        subs[i]=line
    end
end

function multimove(subs,sel)
    text=subs[sel[1]].text
	if not text:match("\\move") then t_error("Missing \\move tag on line 1",1) end
	x1,y1,x2,y2,t=text:match("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)([^%)]*)%)")
	m1=x2-x1 m2=y2-y1
	poscheck=0
    for z=2,#sel do
        progress("Synchronizing movement... "..z.."/"..#sel)
	line=subs[sel[z]]
        text=line.text
	p1,p2=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
	if p1 then text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)","\\move%(%1,%2,"..round(p1+m1,2)..","..round(p2+m2,2)..t.."%)")
	else poscheck=1 end
	line.text=text
	subs[sel[z]]=line
    end
	if poscheck==1 then t_error("Some lines are missing \\pos tags") end
end

function randomove(subs,sel)
    T=true
    RMGUI={
    {x=0,y=0,width=2,class="checkbox",name="rmt",label="Time:",value=rmt},
    {x=2,y=0,width=4,class="intedit",name="slow",value=slowd or 50,hint="max slowdown to ... %",max=100,min=1},
    {x=6,y=0,class="label",label="%"},
    
    {x=0,y=1,width=2,class="checkbox",name="rms",label="Space:",value=rms},
    {x=2,y=1,class="checkbox",name="rm1",label="x1"},
    {x=3,y=1,class="checkbox",name="rm2",label="y1"},
    {x=4,y=1,class="checkbox",name="rm3",label="x2",value=T},
    {x=5,y=1,class="checkbox",name="rm4",label="y2",value=T},
    
    {x=0,y=2,width=2,class="label",label="      Distance:"},
    {x=2,y=2,width=4,class="floatedit",name="rmdist",value=rmd or 0},
    {x=0,y=3,width=2,class="label",label="      Direction:"},
    {x=2,y=3,width=2,class="checkbox",name="plus",label="positive",value=T},
    {x=4,y=3,width=2,class="checkbox",name="minus",label="negative",value=T},
    
    {x=0,y=4,width=7,height=4,class="textbox",value="Time - \\move direction doesn't change.\n'50%' means text will move between 50 and 100% of original distance.\n\nSpace - Given coordinates change within given distance and direction.\n\nTime and Space may be combined, but it makes more sense to use just one."}
    }
    P,rez=ADD(RMGUI,{"OK","Cancel"},{ok='OK',close='Cancel'})
    if P=="Cancel" then ak() end
    
    rmt=rez.rmt rms=rez.rms
    slowd=rez.slow rmd=rez.rmdist
    rmdp=rez.plus rmdm=rez.minus
    
    if not rmt and not rms then t_error("Neither Time nor Space selected.\nSpace-time travel failed.",1) end
    
    plus=0 minus=0
    if rmdp then plus=rmd*100 end
    if rmdm then minus=(0-rmd)*100 end
    
    for z,i in ipairs(sel) do
        progress("Randomizing movement... "..z.."/"..#sel)
	line=subs[i]
        text=line.text
	if text:match("\\move") then
	  if rmt then
	    movt1,movt2=gettimes(line.start_time,line.end_time)
	    text=text:gsub("(\\move%([%d%.%-]+,[%d%.%-]+,[%d%.%-]+,[%d%.%-]+)%)","%1,"..movt1..","..movt2..")")
	    movt3=math.random(movt2,movt2*(100/slowd))
	    text=text:gsub("(\\move%([%d%.%-]+,[%d%.%-]+,[%d%.%-]+,[%d%.%-]+),([%d%.,%-]+)%)","%1,"..movt1..","..movt3..")")
	  end
	  if rms then
	    text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
	    function(a,b,c,d)
	    if rez.rm1 then a=a+math.random(minus,plus)/100 end
	    if rez.rm2 then b=b+math.random(minus,plus)/100 end
	    if rez.rm3 then c=c+math.random(minus,plus)/100 end
	    if rez.rm4 then d=d+math.random(minus,plus)/100 end
	    return "\\move("..a..","..b..","..c..","..d end)
	  end
	end
	line.text=text
	subs[i]=line
    end
end

function modifier(subs,sel)
    post=res.post force=res.force xx=res.eks yy=res.wai
    _,rr=res.rndec:gsub("0","")
    FR={"frx","fry","frz"}
    for z,i in ipairs(sel) do
        progress("Morphing... "..z.."/"..#sel)
	line=subs[i]
	text=line.text

	if res.mod=="round numbers" then
		if text:match("\\pos") and res.rnd=="all" or text:match("\\pos") and res.rnd=="pos" then
		  text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) return "\\pos("..round(a,rr)..","..round(b,rr)..")" end)
		end
		if text:match("\\org") and res.rnd=="all" or text:match("\\org") and res.rnd=="org" then
		  text=text:gsub("\\org%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) return "\\org("..round(a,rr)..","..round(b,rr)..")" end)
		end
		if text:match("\\move") and res.rnd=="all" or text:match("\\move") and res.rnd=="move" then
		  text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(mo1,mo2,mo3,mo4)
		  return "\\move("..round(mo1,rr)..","..round(mo2,rr)..","..round(mo3,rr)..","..round(mo4,rr) end)
		end
		if text:match("\\i?clip") and res.rnd=="all" or text:match("\\i?clip") and res.rnd=="clip" then
		  for klip in text:gmatch("\\i?clip%([^%)]+%)") do
		    if klip:match("m") then rrr=0 else rrr=rr end
		    klip2=klip:gsub("([%d%.%-]+)",function(c) return round(c,rrr) end)
		    klip=esc(klip)
		    text=text:gsub(klip,klip2)
		  end
		end
		if text:match("\\p1") and res.rnd=="all" or text:match("\\p1") and res.rnd=="mask" then
		  tags=text:match(STAG)
		  text=text:gsub(STAG,"") :gsub("([%d%.%-]+)",function(m) return round(m,rr) end)
		  text=tags..text
		end
	end

	if res.mod=="fullmovetimes" or res.mod=="fulltranstimes" then
		start=line.start_time
		endt=line.end_time
		startf=ms2fr(start)
		endf=ms2fr(endt)
		start2=fr2ms(startf)
		endt2=fr2ms(endf-1)
		tim=fr2ms(1)
		movt1=start2-start+tim
		movt2=endt2-start+tim
		movt=movt1..","..movt2
	end

	if res.mod=="killmovetimes" then text=text:gsub("\\move%(([^,]+,[^,]+,[^,]+,[^,]+),[^,]+,[^,%)]+","\\move(%1") end
	if res.mod=="fullmovetimes" then text=text:gsub("\\move%(([^,]+,[^,]+,[^,]+,[^,]+).-%)","\\move(%1,"..movt..")") end
	if res.mod=="killtranstimes" then text=text:gsub("\\t%([%d%.%-]-,[%d%.%-]-,","\\t(") end
	if res.mod=="fulltranstimes" then
		text=text
		:gsub("\\t%([%d%.%-]-,[%d%.%-]-,([%d%.]-,)\\","\\t("..movt..",%1\\")
		:gsub("\\t%([%d%.%-]-,[%d%.%-]-,\\","\\t("..movt..",\\")
		:gsub("\\t%(([%d%.]-,)\\","\\t("..movt..",%1\\")
		:gsub("\\t%(\\","\\t("..movt..",\\")
	end

	if res.mod=="move v. clip" then
		if z==1 then v1,v2=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
			if v1==nil then t_error("Error. No \\pos tag on line 1.",true) end
		end
		if z~=1 and text:match("\\pos") then v3,v4=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		  V1=v3-v1	V2=v4-v2
		  if text:match("clip%(m [%d%a%s%-%.]+%)") then
		    ctext=text:match("clip%(m ([%d%a%s%-%.]+)%)")
		    ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return a+V1.." "..b+V2 end)
		    ctext=ctext:gsub("%-","%%-")
		    text=text:gsub("clip%(m "..ctext,"clip(m "..ctext2)
		  end
		  if text:match("clip%(%d+,m [%d%a%s%-%.]+%)") then
		    fac,ctext=text:match("clip%((%d+),m ([%d%a%s%-%.]+)%)")
		    factor=2^(fac-1)
		    ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return a+factor*V1.." "..b+factor*V2 end)
		    ctext=ctext:gsub("%-","%%-")
		    text=text:gsub(",m "..ctext,",m "..ctext2)
		  end
		end
	end

	if res.mod=="set origin" then
		text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",
		function(a,b) return "\\pos("..a..","..b..")\\org("..a+res.eks..","..b+res.wai..")" end)
	end

	if res.mod=="calculate origin" then
		local c={}
		local c2={}
		x1,y1,x2,y2,x3,y3,x4,y4=text:match("clip%(m ([%d%-]+) ([%d%-]+) l ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+) ([%d%-]+)")
		cor1={x=tonumber(x1),y=tonumber(y1)} table.insert(c,cor1) table.insert(c2,cor1)
		cor2={x=tonumber(x2),y=tonumber(y2)} table.insert(c,cor2) table.insert(c2,cor2)
		cor3={x=tonumber(x3),y=tonumber(y3)} table.insert(c,cor3) table.insert(c2,cor3)
		cor4={x=tonumber(x4),y=tonumber(y4)} table.insert(c,cor4) table.insert(c2,cor4)
		table.sort(c,function(a,b) return tonumber(a.x)<tonumber(b.x) end)	-- sorted by x
		table.sort(c2,function(a,b) return tonumber(a.y)<tonumber(b.y) end)	-- sorted by y
		-- i don't even know myself how all this shit works
		xx1=c[1].x	yy1=c[1].y
		xx2=c[4].x	yy2=c[4].y
		yy3=c2[1].y	xx3=c2[1].x
		yy4=c2[4].y	xx4=c2[4].x
		distx1=c[2].x-c[1].x	disty1=c[2].y-c[1].y
		distx2=c[4].x-c[3].x	disty2=c[4].y-c[3].y
		distx3=c2[2].x-c2[1].x		disty3=c2[2].y-c2[1].y
		distx4=c2[4].x-c2[3].x		disty4=c2[4].y-c2[3].y
		
		-- x/y factor / angle / whatever
		fx1=math.abs(disty1/distx1)
		fx2=math.abs(disty2/distx2)
		fx3=math.abs(distx3/disty3)
		fx4=math.abs(distx4/disty4)
		
		-- determine if y is going up or down
		cy=1
		  if c[2].y>c[1].y then cx1=round(xx1-(yy1-cy)/fx1) else cx1=round(xx1+(yy1-cy)/fx1) end
		  if c[4].y>c[3].y then cx2=round(xx2-(yy2-cy)/fx2) else cx2=round(xx2+(yy2-cy)/fx2) end
		  top=cx2-cx1
		cy=500
		  if c[2].y>c[1].y then cx1=round(xx1-(yy1-cy)/fx1) else cx1=round(xx1+(yy1-cy)/fx1) end
		  if c[4].y>c[3].y then cx2=round(xx2-(yy2-cy)/fx2) else cx2=round(xx2+(yy2-cy)/fx2) end
		  bot=cx2-cx1
		if top>bot then cy=c2[4].y ycalc=1 else cy=c2[1].y ycalc=-1 end
		
		-- LOOK FOR ORG X
		repeat
		  if c[2].y>c[1].y then cx1=round(xx1-(yy1-cy)/fx1) else cx1=round(xx1+(yy1-cy)/fx1) end
		  if c[4].y>c[3].y then cx2=round(xx2-(yy2-cy)/fx2) else cx2=round(xx2+(yy2-cy)/fx2) end
		  cy=cy+ycalc
		until cx1>=cx2 or math.abs(cy)==50000
		org1=cx1
		
		-- determine if x is going left or right
		cx=1
		  if c2[2].x>c2[1].x then cy1=round(yy3-(xx3-cx)/fx3) else cy1=round(yy3+(xx3-cx)/fx3) end
		  if c2[4].x>c2[3].x then cy2=round(yy4-(xx4-cx)/fx4) else cy2=round(yy4+(xx4-cx)/fx4) end
		  left=cy2-cy1
		cx=500
		  if c2[2].x>c2[1].x then cy1=round(yy3-(xx3-cx)/fx3) else cy1=round(yy3+(xx3-cx)/fx3) end
		  if c2[4].x>c2[3].x then cy2=round(yy4-(xx4-cx)/fx4) else cy2=round(yy4+(xx4-cx)/fx4) end
		  rite=cy2-cy1
		if left>rite then cx=c[4].x xcalc=1 else cx=c[1].x xcalc=-1 end
		
		-- LOOK FOR ORG Y
		repeat
		  if c2[2].x>c2[1].x then cy1=round(yy3-(xx3-cx)/fx3) else cy1=round(yy3+(xx3-cx)/fx3) end
		  if c2[4].x>c2[3].x then cy2=round(yy4-(xx4-cx)/fx4) else cy2=round(yy4+(xx4-cx)/fx4) end
		  cx=cx+xcalc
		until cy1>=cy2 or math.abs(cx)==50000
		org2=cy1
		
		text=text:gsub("\\org%([^%)]+%)","")
		text=addtag("\\org("..org1..","..org2..")",text)
	end

	if res.mod=="set rotation" then rotinhell()
		rota=res.freeze
		for f=1,3 do rot=FR[f]
		  if res[rot] then text=addtag3("\\"..rot..rota,text) end
		end
	end

	if res.mod=="rotate 180" then rotinhell()
		nontra=text:gsub("\\t%b()","")
		for f=1,3 do rot=FR[f]
		  if res[rot] then
		    if nontra:match("\\"..rot) then text=flip(rot,text) else text=addtag3("\\"..rot.."180",text) end
		  end
		end
	end

	if res.mod=="negative rot" then rotinhell()
		for f=1,3 do rot=FR[f]
		  if res[rot] then text=negative(text,180,"\\"..rot) end
		end
	end

	if res.mod=="vector2rect." then
		text=text:gsub("\\(i?)clip%(m ([%d%.%-]+) ([%d%.%-]+) l ([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+)%)","\\%1clip(%2,%3,%6,%7)")
	end

	if res.mod=="rect.2vector" then
		text=text:gsub("\\(i?)clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)",function(ii,a,b,c,d) 
		a,b,c,d=round4(a,b,c,d) return string.format("\\"..ii.."clip(m %d %d l %d %d %d %d %d %d)",a,b,c,b,c,d,a,d) end)
	end

	if res.mod=="clip scale" and text:match("\\i?clip%(%d-,?m") then
		oscf=text:match("\\i?clip%((%d+),m")
		if oscf then fact1=2^(oscf-1) else fact1=1 end
		force=round(force)
		if force<1 then force=1 end
		fact2=2^(force-1)
		text=text:gsub("(\\i?clip%()(%d*,?)m ([^%)]+)%)",function(a,b,c)
		return a..force..",m "..c:gsub("([%d%.%-]+)",function(d) return round(d/fact1*fact2) end)..")" end)
		:gsub("1,m","m")
	end

	if res.mod=="find centre" then
		text=text:gsub("\\pos%([^%)]+%)","") t2=text
		text=text:gsub("\\clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c,d)
		x=round(a/2+c/2) y=round(b/2+d/2) return "\\pos("..x..","..y..")" end)
		if t2==text then t_error("Requires rectangular clip",1) end
	end

	if res.mod=="extend mask" then
		if xx==0 and yy==0 then t_error("Error. Both given values are 0.\nUse the Teleporter X and Y fields.",true) end
		draw=text:match("}m ([^{]+)")
		draw2=draw:gsub("([%d%.%-]+) ([%d%.%-]+)",function(a,b)
		if tonumber(a)>0 then ax=xx elseif tonumber(a)<0 then ax=0-xx else ax=0 end
		if tonumber(b)>0 then by=yy elseif tonumber(b)<0 then by=0-yy else by=0 end
		return a+ax.." "..b+by end)
		draw=esc(draw)
		text=text:gsub("(}m )"..draw,"%1"..draw2)
	end

	if res.mod=="flip mask" then
		draw=text:match("}m ([^{]+)")
		draw2=draw:gsub("([%d%.%-]+) ([%d%.%-]+)",function(a,b) return 0-a.." "..b end)
		draw=esc(draw)
		text=text:gsub("(}m )"..draw,"%1"..draw2)
	end

	if res.mod=="adjust drawing" then
		if not text:match("\\p%d") then ak() end
		-- drawing 2 clip
		if not text:match("\\i?clip") then
		  klip="\\clip("..text:match("\\p1[^}]-}(m [^{]*)")..")"
		  scx=text:match("\\fscx([%d%.]+)") or 100
		  scy=text:match("\\fscy([%d%.]+)") or 100
		  if text:match("\\pos") then
		    local xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		    xx=round(xx) yy=round(yy)
		    coord=klip:match("\\clip%(m ([^%)]+)%)")
		    coord2=coord:gsub("([%d%-]+)%s([%d%-]+)",function(a,b) return round(a*scx/100+xx).." "..round(b*scy/100+yy) end)
		    coord=coord:gsub("%-","%%-")
		    klip=klip:gsub(coord,coord2)
		  end
		  if not text:match("\\pos") then text=text:gsub("^{","{\\pos(0,0)") end
		  text=addtag(klip,text)
		-- clip 2 drawing
		else
		  text=text:gsub("\\i?clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)",function(a,b,c,d)
		    a,b,c,d=round4(a,b,c,d) return string.format("\\clip(m %d %d l %d %d %d %d %d %d)",a,b,c,b,c,d,a,d) end)
		  klip=text:match("\\i?clip%((m.-)%)")
		  if text:match("\\pos") then
		  local xx,yy=text:match("\\pos%(([%d%.%-]+),([%d%.%-]+)%)")
		    xx=round(xx) yy=round(yy)
		    coord=klip:match("m ([%d%a%s%-]+)")
		    coord2=coord:gsub("([%d%-]+)%s([%d%-]+)",function(a,b) return a-xx.." "..b-yy end)
		    coord=coord:gsub("%-","%%-")
		    klip=klip:gsub(coord,coord2)
		  end
		  text=text:gsub("(\\p1[^}]-})(m [^{]*)","%1"..klip)
		  if not text:match("\\pos") then text=text:gsub("^{","{\\pos(0,0)") end
		  if text:match("\\an") then text=text:gsub("\\an%d","\\an7") else text=text:gsub("^{","{\\an7") end
		  if text:match("\\fscx") then text=text:gsub("\\fscx[%d%.]+","\\fscx100") else text=text:gsub("\\p1","\\fscx100\\p1") end
		  if text:match("\\fscy") then text=text:gsub("\\fscy[%d%.]+","\\fscy100") else text=text:gsub("\\p1","\\fscy100\\p1") end
		  text=text:gsub("\\i?clip%(.-%)","")
		end
	end

	if res.mod=="randomask" then
		draw=text:match("}m ([^{]+)")
		draw2=draw:gsub("([%d%.%-]+)",function(a) return a+math.random(0-force,force) end)
		draw=esc(draw)
		text=text:gsub("(}m )"..draw,"%1"..draw2)
	end

	if res.mod=="randomize..." then
		if z==1 then
		randomgui={
		{x=0,y=0,class="label",label="randomization value"},
		{x=1,y=0,class="floatedit",name="random",value=rnd or 3},
		{x=0,y=1,class="label",label="rounding"},
		{x=1,y=1,class="dropdown",name="dec",items={"1","0.1","0.01","0.001"},value=rd or "0.1",},
		{x=1,y=2,class="edit",name="randomtag",value=rt,hint="separate multiple tags with a comma"},
		{x=1,y=3,class="edit",name="partag1",hint="pos, move, org, clip, (fad)",value=rtx},
		{x=1,y=4,class="edit",name="partag2",hint="pos, move, org, clip, (fad)",value=rty},
		{x=0,y=2,class="checkbox",name="ntag",label="standard type tag - \\",value=rnt,hint="\\[tag][number]"},
		{x=0,y=3,class="checkbox",name="ptag1",label="parenthesis tag x - \\",value=rpt1,hint="\\tag(X,y)"},
		{x=0,y=4,class="checkbox",name="ptag2",label="parenthesis tag y - \\",value=rpt2,hint="\\tag(x,Y)"}
		}
		press,rez=ADD(randomgui,{"Randomize","Disintegrate"},{ok='Randomize',close='Disintegrate'})
		if press=="Disintegrate" then ak() end
		rt=rez.randomtag:gsub(" ","")   rtx=rez.partag1   rty=rez.partag2	rd=rez.dec
		_,deci=rez.dec:gsub("0","")    rnd=rez.random	rnt=rez.ntag   rpt1=rez.ptag1   rpt2=rez.ptag2
		end
		
		-- standard tags
		if rez.ntag then
		  for tg in rt:gmatch("[^,]+") do
		     text=text:gsub("(\\"..tg..")([%d%.%-]+)",function(tag,val)
			rndm=math.random(-100,100)/100*rnd
			nval=val+rndm
			if nval<0 and noneg:match(tag) then nval=math.abs(nval) end
			return tag..round(nval,deci)
		     end)
		     text=text:gsub("(\\"..tg..")(&H%x%x&)",function(tag,val)
			rndm=math.random(-100,100)/100*rnd
			val=val:match("&H(%x%x)&")
			nval=(tonumber(val,16))
			nval=round(nval+rndm)
			if nval<0 then nval=0 end
			if nval>255 then nval=255 end
			nval=tohex(nval)
			return tag.."&H"..nval.."&"
		     end)
		  end
		end
		
		-- parenthesis tags
		if rez.ptag1 or rez.ptag2 then
		  rndm=math.random(-100,100)/100*rnd
		  if rez.ptag1 then
		    text=text:gsub("\\"..rtx.."%(([%d%.%-]+),([%d%.%-]+)",
			function(x,y) return "\\"..rtx.."("..round((x+rndm),deci)..","..y end)
		    :gsub("\\"..rtx.."%(([%d%.%-]+,[%d%.%-]+,)([%d%.%-]+),([%d%.%-]+)",
			function(a,x,y) return "\\"..rtx.."("..a..round((x+rndm),deci)..","..y end)
		  end
		  if rez.ptag2 then
		    text=text:gsub("\\"..rty.."%(([%d%.%-]+),([%d%.%-]+)",
			function(x,y) return "\\"..rty.."("..x..","..round((y+rndm),deci) end)
		    :gsub("\\"..rty.."%(([%d%.%-]+,[%d%.%-]+,)([%d%.%-]+),([%d%.%-]+)",
			function(a,x,y) return "\\"..rty.."("..a..x..","..round((y+rndm),deci) end)
		  end
		end
	end

	if res.mod=="letterbreak" then
		text=text:gsub("%s*\\N%s*"," ")
		:gsub("^([^{]*)",function(t) return re.sub(t,"([\\w[:punct:]\\s])","\\1\\\\N") end)
		:gsub("}([^{]*)",function(t) return "}"..re.sub(t,"([\\w[:punct:]\\s])","\\1\\\\N") end)
		:gsub("\\N$","")
	end
	
	if res.mod=="wordbreak" then
		text=text:gsub(" *$","")
		:gsub("^([^{]*)",function(t) return t:gsub("%s+"," \\N") end)
		:gsub("(}[^{]*)",function(t) return t:gsub("%s+"," \\N") end)
	end

	line.text=text
        subs[i]=line
    end
end

function movetofbf(subs,sel)
    fra={}
    for z=#sel,1,-1 do
    i=sel[z]
    progress("Dissecting line... "..(#sel-z+1).."/"..#sel)
        line=subs[i]
        text=line.text
	styleref=stylechk(subs,line.style)
	start=line.start_time
	endt=line.end_time
	startf=ms2fr(start)
	endf=ms2fr(endt)
	frames=endf-1-startf
	frnum=frames
	table.insert(fra,frnum)
	l2=line
	frdiff=(fr2ms(startf+1)-fr2ms(startf))/2
	-- Real Start, End, Duration
	RS=fr2ms(startf)
	RE=fr2ms(endf)
	RD=RE-RS

	for frm=endf-1,startf,-1 do
	l2.text=text
		-- move
		if text:match("\\move") then
		    m1,m2,m3,m4=text:match("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
		    	mvstart,mvend=text:match("\\move%([%d%.%-]+,[%d%.%-]+,[%d%.%-]+,[%d%.%-]+,([%d%.%-]+),([%d%.%-]+)")
			if mvstart==nil then mvstart=0 end
			if mvend==nil then mvend=RD end
			moffset=mvstart
			CS=fr2ms(startf+frnum)
			frcount=CS-RS
			mlimit=tonumber(mvend)
			mpart=frcount-tonumber(mvstart)+frdiff
			mwhole=mvend-mvstart
		    pos1=round((((m3-m1)/mwhole)*mpart+m1),2)
		    pos2=round((((m4-m2)/mwhole)*mpart+m2),2)
		    xdiff=pos1-m1 ydiff=pos2-m2
			if mpart<0 then pos1=m1 pos2=m2 end
			if mpart>mlimit-moffset then pos1=m3 pos2=m4 end
		    l2.text=text:gsub("\\move%([^%)]*%)","\\pos("..pos1..","..pos2..")")
		    if res.c2fbf and frm>1 then
			l2.text=l2.text:gsub("(\\i?clip%()([^%)]*)%)",function(kl,ip)
				ip=ip:gsub("([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(a,b,c,d)
				return a+xdiff..","..b+ydiff..","..c+xdiff..","..d+ydiff end)
				:gsub("([%d%.%-]+) ([%d%.%-]+)",function(a,b)
				return round(a+xdiff).." "..round(b+ydiff) end)
			return kl..ip..")" end)
		    end
		end
		-- fade
		if text:match("\\fad%(") then
		    l2.text=l2.text:gsub("\\t%b()",function(t) return t:gsub("\\","|") end)
		    f1,f2=text:match("\\fad%(([%d%.]+),([%d%.]+)")
		    linealfa=text:match("^{[^}]-\\alpha(&H%x%x&)") or "&H00&"
		    l2.text=l2.text
		    :gsub("^({[^}]-)\\alpha&H%x%x&","%1")
		    :gsub("{(.-)\\fad%b()(.-)}","{\\alpha&HFF&%1%2\\t(0,"..f1..",\\alpha"..linealfa..")\\t("..RD-f2..",0,\\alpha&HFF&)}")
		    :gsub("(.){(.-)(\\alpha&H%x%x&)(.-)}","%1{%2\\alpha&HFF&\\t(0,"..f1..",%3)\\t("..RD-f2..",0,\\alpha&HFF&)%4}")
		    for c=1,4 do
		    l2.text,c=l2.text:gsub("{(.-)(\\"..c.."a)(&H%x%x&)(.-)}","{%1%2&HFF&\\t(0,"..f1..",%2%3)\\t("..RD-f2..",0,%2&HFF&)%4}")
		    end
		    l2.text=l2.text:gsub("|","\\")
		end
	   
	    lastags2=""
	    l2.text=l2.text:gsub(ATAG,function(tg) return cleantr(tg) end)
	    :gsub(ATAG,function(tg) if tg:match("\\t") then return terraform(tg) else return tg end end)
	    
	    l2.start_time=fr2ms(frm)
	    l2.end_time=fr2ms(frm+1)
	    subs.insert(i+1,l2)
	    frnum=frnum-1
	end
	line.end_time=endt
	line.comment=true
	line.text=text
	subs[i]=line
	if res.delfbf then subs.delete(i) end
    end
    -- selection
    sel2={}
    if res.delfbf then fakt=0 else fakt=1 end
    for s=#sel,1,-1 do
	sfr=fra[#sel-s+1]
	-- shift new sel
	for s2=#sel2,1,-1 do  sel2[s2]=sel2[s2]+sfr+fakt  end
	-- add to new sel
	for f=1,sfr+fakt do  table.insert(sel2,sel[s]+f)  end
	-- add orig line
	if res.delfbf then table.insert(sel2,sel[s]) end
    end
    sel=sel2
    return sel
end

function terraform(tags)
ftags=""
lastags1=""
    for tra in tags:gmatch("(\\t%b())") do
	trstart=0 trend=RD acc=1
	trtimes=tra:match("\\t%(([%d,%.]*)")	_,ttt=trtimes:gsub(",","")
	if ttt==1 then acc=tra:match("([%d%.]+)") end
	if ttt==2 then trstart,trend=tra:match("(%d+),(%d+),") end
	if ttt==3 then trstart,trend,acc=tra:match("(%d+),(%d+),([%d%.]+),") end
	if trend=="0" then trend=RD end
	toffset=trstart
	CS=fr2ms(startf+frnum)
	frcount=CS-RS
	tlimit=tonumber(trend)
	tpart=frcount-tonumber(trstart)+frdiff
	twhole=trend-trstart
	nontra=tags:gsub("\\t%b()","")
	acc_fac=(tpart-1)^acc/(twhole-1)^acc
	-- most tags
	for tg, valt in tra:gmatch("\\(%a+)([%d%.%-]+)") do
		val1=nil
		if nontra:match("^{[^}]-\\"..tg) then val1=nontra:match("^{[^}]-\\"..tg.."([%d%.%-]+)") end
		if lastags2:match("\\"..tg) then val1=lastags2:match("\\"..tg.."([%d%.%-]+)") end
		if nontra:match("\\"..tg) then val1=nontra:match("\\"..tg.."([%d%.%-]+)") end
		if lastags1:match("\\"..tg) then val1=lastags1:match("\\"..tg.."([%d%.%-]+)") end
		if val1==nil then
		if tg=="bord" or tg=="xbord" or tg=="ybord" then val1=styleref.outline end
		if tg=="shad" or tg=="xshad" or tg=="yshad" then val1=styleref.shadow end
		if tg=="fs" then val1=styleref.fontsize end
		if tg=="fsp" then val1=styleref.spacing end
		if tg=="frz" then val1=styleref.angle end
		if tg=="fscx" then val1=styleref.scale_x end
		if tg=="fscy" then val1=styleref.scale_y end
		if tg=="blur" or tg=="be" or tg=="fax" or tg=="fay" or tg=="frx" or tg=="fry" then val1=0 end
		end
		valf=round(acc_fac*(valt-val1)+val1,2)
		if tpart<0 then valf=val1 end
		if tpart>tlimit-toffset then valf=valt end
		ftags=ftags.."\\"..tg..valf
		--logg("\n val1: "..val1.."  valf: "..valf.."  tpart: "..tpart.."  twhole: "..twhole)
	end
	-- clip
	if tra:match("\\i?clip%([%d%-]") then
	ctype,c1,c2,c3,c4=nontra:match("(\\i?clip%()([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
	if not ctype then t_error("Looks like you're transforming a clip that's not set in the first place.",true) end
	ktype,k1,k2,k3,k4=tra:match("(\\i?clip%()([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
	tc1=round((((k1-c1)/twhole)*tpart+c1),2)
	tc2=round((((k2-c2)/twhole)*tpart+c2),2)
	tc3=round((((k3-c3)/twhole)*tpart+c3),2)
	tc4=round((((k4-c4)/twhole)*tpart+c4),2)
	if tpart<0 then tc1=c1 tc2=c2 tc3=c3 tc4=c4 end
	if tpart>tlimit-toffset then tc1=k1 tc2=k2 tc3=k3 tc4=k4 end
	ftags=ftags..ktype..tc1..","..tc2..","..tc3..","..tc4..")"
	end
	-- colour/alpha
	tra=tra:gsub("\\1c","\\c")
	nontra=nontra:gsub("\\1c","\\c")
	for tg, valt in tra:gmatch("\\(%w+)(&H%x+&)") do
		val1=nil
		if nontra:match("^{[^}]-\\"..tg.."&") then val1=nontra:match("^{[^}]-\\"..tg.."(&H%x+&)") end
		if lastags2:match("\\"..tg) then val1=lastags2:match("\\"..tg.."(&H%x+&)") end
		if nontra:match("\\"..tg) then val1=nontra:match("\\"..tg.."(&H%x+&)") end
		if lastags1:match("\\"..tg) then val1=lastags1:match("\\"..tg.."(&H%x+&)") end
		if val1==nil then
		if tg=="c" then val1=styleref.color1:gsub("H%x%x","H") end
		if tg=="2c" then val1=styleref.color2:gsub("H%x%x","H") end
		if tg=="3c" then val1=styleref.color3:gsub("H%x%x","H") end
		if tg=="4c" then val1=styleref.color4:gsub("H%x%x","H") end
		if tg=="1a" then val1=styleref.color1:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="2a" then val1=styleref.color2:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="3a" then val1=styleref.color3:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="4a" then val1=styleref.color4:gsub("(H%x%x)%x%x%x%x%x%x","%1") end
		if tg=="alpha" then val1="&H00&" end
		end
		valf=acgrad(val1,valt,twhole,tpart,acc)
		if tpart<0 then valf=val1 end
		if tpart>tlimit-toffset then valf=valt end
		ftags=ftags.."\\"..tg..valf
	end
	lastags1=lastags1..ftags
	lastags1=duplikill(lastags1)
    end
	lastags2=lastags2..ftags
	lastags2=duplikill(lastags2)
	tags=tags:gsub("\\t%b()","") :gsub("^({[^}]*)}","%1"..ftags.."}")
	tags=duplikill(tags)
    return tags
end

function joinfbflines(subs,sel)
    join=round(res.force)
    if join<2 then t_error("Minimum of lines to join is 2.\nUse the field at the bottom left to enter a number.",1) end
    count=1
    for z,i in ipairs(sel) do
        line=subs[i]
	line.effect=count
	if z==1 then line.effect="1" end
        subs[i]=line
	count=count+1
	if count>join then count=1 end
    end
    -- delete & time
    total=#sel
    for z=#sel,1,-1 do
	i=sel[z]
	line=subs[i]
	if line.effect==tostring(join) then endtime=line.end_time end
	if i==total then endtime=line.end_time end
	if line.effect=="1" then line.end_time=endtime line.effect="" subs[i]=line
	else subs.delete(i) table.remove(sel,#sel) end
    end
    return sel
end

function rotinhell()
if not res.frx and not res.fry and not res.frz then t_error("No rotations selected.\nCheck at least one of frx/fry/frz.",1) end
end

function negative(text,m,rot)
text=text:gsub(rot.."([%d%.]+)",function(r) if tonumber(r)>m then return rot..r-360 end end)
return text
end

function transclip(subs,sel,act)
	line=subs[act]
	text=line.text
	if not text:match("\\i?clip%([%d%.%-]+,") then t_error("Error: rectangular clip required on active line.",1) end
	ctype,cc1,cc2,cc3,cc4=text:match("(\\i?clip)%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)%)")
	clipconfig={
	{x=0,y=0,width=2,class="label",label="   \\clip("},
	{x=2,y=0,width=3,class="edit",name="orclip",value=cc1..","..cc2..","..cc3..","..cc4},
	{x=5,y=0,class="label",label=")"},
	{x=0,y=1,width=2,class="label",label="\\t(\\clip("},
	{x=2,y=1,width=3,class="edit",name="klip",value=cc1..","..cc2..","..cc3..","..cc4},
	{x=5,y=1,class="label",label=")"},
	{x=0,y=2,width=5,class="label",label="Move x and y for new coordinates by:"},
	{x=0,y=3,class="label",label="x:"},
	{x=3,y=3,class="label",label="y:"},
	{x=1,y=3,width=2,class="floatedit",name="eks"},
	{x=4,y=3,class="floatedit",name="wai"},
	{x=0,y=4,width=5,class="label",label="Start / end / accel:"},
	{x=1,y=5,width=2,class="edit",name="accel",value="0,0,1,"},
	{x=4,y=5,class="checkbox",name="two",label="use next line's clip",hint="use clip from the next line (line will be deleted)"},
	}
	buttons={"Transform","Calculate coordinates","Cancel"}
	repeat
	    if P=="Calculate coordinates" then
		xx=res.eks	yy=res.wai
		for key,v in ipairs(clipconfig) do
		    if v.name=="klip" then v.value=round(cc1+xx,3)..","..round(cc2+yy,3)..","..round(cc3+xx,3)..","..round(cc4+yy,3) end
		    if v.name=="accel" then v.value=res.accel end
		end
	    end
	P,res=ADD(clipconfig,buttons,{ok='Transform',close='Cancel'})
	if P=="Cancel" then ak() end
	until P~="Calculate coordinates"
	if P=="Transform" then newcoord=res.klip end
	
    if res.two then
	nextline=subs[act+1]
	nextext=nextline.text
	if not nextext:match("\\i?clip%([%d%.%-]+,") then t_error("Error: second line must contain a rectangular clip.",1)
	else
	  nextclip=nextext:match("\\i?clip%(([%d%.%-,]+)%)")
	  text=text:gsub("^({\\[^}]*)}","%1\\t("..res.accel..ctype.."("..nextclip.."))}")
	end
    else
	text=text:gsub("^({\\[^}]*)}","%1\\t("..res.accel..ctype.."("..newcoord.."))}")
    end	
    
    text=text:gsub("0,0,1,\\","\\")
    line.text=text
    subs[act]=line
    if res.two then subs.delete(act+1) end
end

function clone(subs,sel)
    for z,i in ipairs(sel) do
        progress("Cloning... "..z.."/"..#sel)
	line=subs[i]
        text=line.text
	if not text:match("^{\\") then text=text:gsub("^","{\\clone}") end

	if res.cpos then
		if z==1 then posi=text:match("\\pos%(([^%)]-)%)") end
		if z>1 and text:match("\\pos") and posi then text=text:gsub("\\pos%b()","\\pos("..posi..")") end
		if z>1 and not text:match("\\pos") and not text:match("\\move") and posi and res.cre then
			text=text:gsub("^{\\","{\\pos%("..posi.."%)\\") end
		if z==1 then move=text:match("\\move%(([^%)]-)%)") end
		if z>1 and text:match("\\move") and move then text=text:gsub("\\move%b()","\\move("..move..")") end
		if z>1 and not text:match("\\move") and not text:match("\\pos") and move and res.cre then
			text=text:gsub("^{\\","{\\move("..move..")\\") end
	end
	
	if res.corg then
	    if z==1 then orig=text:match("\\org%(([^%)]-)%)") end
	    if z>1 and orig then
		if text:match("\\org") then text=text:gsub("\\org%b()","\\org("..orig..")")
		elseif res.cre then text=text:gsub("^({\\[^}]*)}","%1\\org("..orig..")}") end
	    end
	end
	
	if res.copyrot then
	    if z==1 then rotz=text:match("\\frz([%d%.%-]+)") rotx=text:match("\\frx([%d%.%-]+)") roty=text:match("\\fry([%d%.%-]+)") end
	    if z>1 then
		if rotz then if res.cre then text=addtag3("\\frz"..rotz,text)
		else text=text:gsub("^({[^}]-\\frz)[%d%.%-]+","%1"..rotz) end end
		if rotx then if res.cre then text=addtag3("\\frx"..rotx,text)
		else text=text:gsub("^({[^}]-\\frx)[%d%.%-]+","%1"..rotx) end end
		if roty then if res.cre then text=addtag3("\\fry"..roty,text)
		else text=text:gsub("^({[^}]-\\fry)[%d%.%-]+","%1"..roty) end end
	    end
	end
	
	if res.cclip then
	    -- line 1 - copy
	    if z==1 then
		ik,klip=text:match("\\(i?)clip%(([^%)]-)%)")
		if klip and klip:match("m") then type1="vector" else type1="normal" end
	    end
	    -- lines 2+ - paste / replace
	    if z>1 and text:match("\\i?clip") and klip then
		ik2,klip2=text:match("\\(i?)clip%(([^%)]-)%)")
		if res.klipmatch then kmatch=ik else kmatch=ik2 end
		if klip2:match("m") then type2="vector" klipv=klip2 else type2="normal" end
		if text:match("\\(i?)clip.-\\(i?)clip") then doubleclip=true ikv,klipv=text:match("\\(i?)clip%((%d?,?m[^%)]-)%)")
		else doubleclip=false end
		if res.combine and type1=="vector" and text:match("\\(i?clip)%(%d?,?m[^%)]-%)") then nklip=klipv.." "..klip else nklip=klip end
		-- 1 clip, stack
		if res.stack and type1~=type2 and not doubleclip then 
		  text=text:gsub("^({\\[^}]*)}","%1\\"..ik.."clip%("..nklip.."%)}")
		-- 2 clips -> not stack
		elseif doubleclip then
		  if type1=="normal" then text=text:gsub("\\(i?clip)%([%d%.,%-]-%)","\\%1%("..nklip.."%)") end
		  if type1=="vector" then text=text:gsub("\\(i?clip)%(%d?,?m[^%)]-%)","\\%1%("..nklip.."%)") end
		-- 1 clip, not stack
		elseif type1==type2 and not doubleclip or not res.stack and not doubleclip then
		  text=text:gsub("\\i?clip%([^%)]-%)","\\"..kmatch.."clip%("..nklip.."%)")
		end
	    end
	    -- lines 2+ / paste / create
	    if z>1 and not text:match("\\i?clip") and klip and res.cre then
		text=text:gsub("^({\\[^}]*)}","%1\\"..ik.."clip%("..klip.."%)}")
	    end
	end
	
	if res.ctclip then
	    if z==1 then tklip=text:match("\\t%([%d%.,]*\\i?clip%(([^%)]-)%)") end
	    if z>1 and text:match("\\i?clip") and tklip then
	    text=text:gsub("\\t%(([%d%.,]*)\\(i?clip)%([^%)]-%)","\\t%(%1\\%2%("..tklip.."%)") end
	    if z>1 and not text:match("\\t%([%d%.,]*\\i?clip") and tklip and res.cre then
	    text=text:gsub("^({\\[^}]*)}","%1\\t%(\\clip%("..tklip.."%)%)}") end
	end

	text=text:gsub("\\clone",""):gsub("{}","")
	line.text=text
	subs[i]=line
    end
    --posi,move,orig,klip,tklip=nil
end

function teleport(subs,sel)
    tpfx=0    tpfy=0
    if res.tpmod then
	telemod={
	{x=2,y=0,class="label",label=" Warped Teleportation"},
	{x=2,y=1,class="floatedit",name="eggs",hint="X"},
	{x=2,y=2,class="floatedit",name="why",hint="Y"}}
	press,rez=ADD(telemod,{"Warped Teleport","Disintegrate"},{close='Disintegrate'})
	if press=="Disintegrate" then ak() end
	tpfx=rez.eggs	tpfy=rez.why
    end
    for z,i in ipairs(sel) do
        progress("Teleporting... "..z.."/"..#sel)
	line=subs[i]
        text=line.text
	style=line.style
	xx=res.eks
	yy=res.wai
	fx=tpfx*(z-1)
	fy=tpfy*(z-1)

	if res.tppos then
	    if res.autopos and not text:match("\\pos") and not text:match("\\move") then text=getpos(subs,text) end
	    text=text:gsub("\\pos%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) return "\\pos("..a+xx+fx..","..b+yy+fy..")" end)
	end

	if res.tporg then
	    text=text:gsub("\\org%(([%d%.%-]+),([%d%.%-]+)%)",function(a,b) return "\\org("..a+xx+fx..","..b+yy+fy..")" end)
	end

	if res.tpmov then
	    text=text:gsub("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",
	    function(a,b,c,d) return "\\move("..a+xx+fx..","..b+yy+fy..","..c+xx+fx..","..d+yy+fy end)
	end

	if res.tpclip then
	    text=text:gsub("clip%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)",function(a,b,c,d)
	    xd=xx+fx yd=yy+fy
	    if res.tpexp then a=a-xd b=b-yd elseif res.tpc1 then a=a+xd b=b+yd end
	    if res.tpexp or res.tpc2 then c=c+xd d=d+yd end
	    return "clip("..a..","..b..","..c..","..d end)
	    
	    if text:match("clip%(m [%d%a%s%-%.]+%)") then
	    ctext=text:match("clip%(m ([%d%a%s%-%.]+)%)")
	    ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return a+xx+fx.." "..b+yy+fy end)
	    ctext=ctext:gsub("%-","%%-")
	    text=text:gsub("clip%(m "..ctext,"clip(m "..ctext2)
	    end
	    
	    if text:match("clip%(%d+,m [%d%a%s%-%.]+%)") then
	    fac,ctext=text:match("clip%((%d+),m ([%d%a%s%-%.]+)%)")
	    factor=2^(fac-1)
	    ctext2=ctext:gsub("([%d%-%.]+)%s([%d%-%.]+)",function(a,b) return a+factor*xx+fx.." "..b+factor*yy+fy end)
	    ctext=ctext:gsub("%-","%%-")
	    text=text:gsub(",m "..ctext,",m "..ctext2)
	    end
	end

	if res.tpmask then
	    draw=text:match("}m ([^{]+)")
	    draw2=draw:gsub("([%d%.%-]+) ([%d%.%-]+)",function(a,b) return round(a+xx+fx).." "..round(b+yy+fy) end)
	    draw=esc(draw)
	    text=text:gsub("(}m )"..draw,"%1"..draw2)
	end

	text=roundpar(text,2)
	line.text=text
	subs[i]=line
    end
end


--	reanimatools	--

function esc(str) str=str:gsub("[%%%(%)%[%]%.%-%+%*%?%^%$]","%%%1") return str end
function round(n,dec) dec=dec or 0 n=math.floor(n*10^dec+0.5)/10^dec return n end
function addtag(tag,text) text=text:gsub("^({\\[^}]-)}","%1"..tag.."}") return text end

function addtag3(tg,txt)
	no_tf=txt:gsub("\\t%b()","")
	tgt=tg:match("(\\%d?%a+)[%d%-&]") val="[%d%-&]"
	if not tgt then tgt=tg:match("(\\%d?%a+)%b()") val="%b()" end
	if not tgt then tgt=tg:match("\\fn") val="" end
	if not tgt then t_error("adding tag '"..tg.."' failed.") end
	if tgt:match("clip") then txt,r=txt:gsub("^({[^}]-)\\i?clip%b()","%1"..tg)
		if r==0 then txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
	elseif no_tf:match("^({[^}]-)"..tgt..val) then txt=txt:gsub("^({[^}]-)"..tgt..val.."[^\\}]*","%1"..tg)
	elseif not txt:match("^{\\") then txt="{"..tg.."}"..txt
	elseif txt:match("^{[^}]-\\t") then txt=txt:gsub("^({[^}]-)\\t","%1"..tg.."\\t")
	else txt=txt:gsub("^({\\[^}]-)}","%1"..tg.."}") end
return txt
end

function round4(a,b,c,d,dec)
	if not dec then dec=1 end
	a=math.floor(a*dec+0.5)/dec
	b=math.floor(b*dec+0.5)/dec
	c=math.floor(c*dec+0.5)/dec
	d=math.floor(d*dec+0.5)/dec
	return a,b,c,d
end

function roundpar(text,dec)
text=text:gsub("(\\%a%a+)(%b())",function(a,b) return a..b:gsub("([%d%.%-]+)",function(c) return round(c,dec) end) end)
return text
end

function getpos(subs,text)
    for g=1,#subs do
        if subs[g].class=="info" then
	    local k=subs[g].key
	    local v=subs[g].value
	    if k=="PlayResX" then resx=v end
	    if k=="PlayResY" then resy=v end
        end
	if resx==nil then resx=0 end
	if resy==nil then resy=0 end
        if subs[g].class=="style" then
            local st=subs[g]
	    if st.name==line.style then
		acleft=st.margin_l	if line.margin_l>0 then acleft=line.margin_l end
		acright=st.margin_r	if line.margin_r>0 then acright=line.margin_r end
		acvert=st.margin_t	if line.margin_t>0 then acvert=line.margin_t end
		acalign=st.align	if text:match("\\an%d") then acalign=text:match("\\an(%d)") end
		aligntop="789" alignbot="123" aligncent="456"
		alignleft="147" alignright="369" alignmid="258"
		if alignleft:match(acalign) then horz=acleft
		elseif alignright:match(acalign) then horz=resx-acright
		elseif alignmid:match(acalign) then horz=resx/2 end
		if aligntop:match(acalign) then vert=acvert
		elseif alignbot:match(acalign) then vert=resy-acvert
		elseif aligncent:match(acalign) then vert=resy/2 end
	    break
	    end
        end
    end
    if horz>0 and vert>0 then 
	if not text:match("^{\\") then text="{\\rel}"..text end
	text=text:gsub("^({\\[^}]-)}","%1\\pos("..horz..","..vert..")}") :gsub("\\rel","")
    end
    return text
end

function gettimes(st,et)
startf=ms2fr(st)
endf=ms2fr(et)
start2=fr2ms(startf)
endt2=fr2ms(endf-1)
tim=fr2ms(1)
movt1=start2-st+tim
movt2=endt2-st+tim
return movt1,movt2
end

function vfcheck()
    if aegisub.project_properties==nil then
	t_error("Current frame unknown.\nProbably your Aegisub is too old.\nMinimum required: r8374.",1)
    end
    vframe=aegisub.project_properties().video_position
    if vframe==nil or fr2ms(1)==nil then t_error("Current frame unknown. Probably no video loaded.",1) end
    if line then
	startf=ms2fr(line.start_time) start2=fr2ms(startf) vft=fr2ms(vframe)
	tim=math.floor((fr2ms(vframe+1)-vft)/2) videopos=vft-line.start_time+tim
    end
end

function detrack(z,sel,retrack,frame)
	if res.layers then
	  for f=1,#retrack do
	    if frame==retrack[f] then fpos=f end
	  end
	  total=#retrack
	else
	  fpos=z
	  total=#sel
	end
	return fpos,total
end

function stylechk(subs,sn)
  for i=1,#subs do
    if subs[i].class=="style" then
      local st=subs[i]
      if sn==st.name then sr=st break end
    end
  end
  if sr==nil then t_error("Style '"..sn.."' doesn't exist.",1) end
  return sr
end

function shiftsel(sel,i,mode)
	if i<sel[#sel] then
	for s=1,#sel do if sel[s]>i then sel[s]=sel[s]+1 end end
	end
	if mode==1 then table.insert(sel,i+1) end
	table.sort(sel)
return sel
end

function flip(rot,text)
    text=text:gsub("\\"..rot.."([%d%.%-]+)",function(r) r=tonumber(r)
	if r>0 then newrot=r-180 else newrot=r+180 end
	return "\\"..rot..newrot end)
    return text
end

function numgrad(V1,V2,total,l,acc)
	acc=acc or 1
	acc_fac=(l-1)^acc/(total-1)^acc
	VC=round(acc_fac*(V2-V1)+V1,2)
return VC
end

function acgrad(C1,C2,total,l,acc)
	acc=acc or 1
	acc_fac=(l-1)^acc/(total-1)^acc
	B1,G1,R1=C1:match("(%x%x)(%x%x)(%x%x)")
	B2,G2,R2=C2:match("(%x%x)(%x%x)(%x%x)")
	A1=C1:match("(%x%x)") R1=R1 or A1
	A2=C2:match("(%x%x)") R2=R2 or A2
	nR1=(tonumber(R1,16))  nR2=(tonumber(R2,16))
	R=acc_fac*(nR2-nR1)+nR1
	R=tohex(round(R))
	CC="&H"..R.."&"
	if B1 then
	nG1=(tonumber(G1,16))  nG2=(tonumber(G2,16))
	nB1=(tonumber(B1,16))  nB2=(tonumber(B2,16))
	G=acc_fac*(nG2-nG1)+nG1
	B=acc_fac*(nB2-nB1)+nB1
	G=tohex(round(G))
	B=tohex(round(B))
	CC="&H"..B..G..R.."&"
	end
return CC
end

function tohex(num)
n1=math.floor(num/16)
n2=num%16
num=tohex1(n1)..tohex1(n2)
return num
end

function tohex1(num)
HEX={"1","2","3","4","5","6","7","8","9","A","B","C","D","E"}
if num<1 then num="0" elseif num>14 then num="F" else num=HEX[num] end
return num
end

function textmod(orig,text)
    tk={}
    tg={}
	text=text:gsub("{\\\\k0}","")
	repeat text,r=text:gsub("{(\\[^}]-)}{(\\[^}]-)}","{%1%2}") until r==0
	vis=text:gsub("%b{}","")
	letrz=re.find(vis,".")
	  for l=1,#letrz do
	    table.insert(tk,letrz[l].str)
	  end
	stags=text:match(STAG) or ""
	text=text:gsub(STAG,"") :gsub("{[^\\}]-}","")
	count=0
	for seq in orig:gmatch("[^{]-"..ATAG) do
	    chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	    pos=re.find(chars,".")
	    if pos==nil then ps=0+count else ps=#pos+count end
	    tgl={p=ps,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=ps
	end
	count=0
	for seq in text:gmatch("[^{]-"..ATAG) do
	    chars,as,tak=seq:match("([^{]-){(%*?)(\\[^}]-)}")
	    pos=re.find(chars,".")
	    if pos==nil then ps=0+count else ps=#pos+count end
	    tgl={p=ps,t=tak,a=as}
	    table.insert(tg,tgl)
	    count=ps
	end
    newline=""
    for i=1,#tk do
	newline=newline..tk[i]
	newt=""
	for n, t in ipairs(tg) do
	    if t.p==i then newt=newt..t.a..t.t end
	end
	if newt~="" then newline=newline.."{"..as..newt.."}" end
    end
    newtext=stags..newline
    text=newtext:gsub("{}","")
    return text
end

function cleantr(tags)
	trnsfrm=""
	for t in tags:gmatch("\\t%b()") do trnsfrm=trnsfrm..t end
	tags=tags:gsub("\\t%b()","")
	:gsub("^({[^}]*)}","%1"..trnsfrm.."}")
	return tags
end

tags1={"blur","be","bord","shad","xbord","xshad","ybord","yshad","fs","fsp","fscx","fscy","frz","frx","fry","fax","fay"}
tags2={"c","2c","3c","4c","1a","2a","3a","4a","alpha"}
tags3={"pos","move","org","fad"}

function duplikill(tagz)
	tagz=tagz:gsub("\\t%b()",function(t) return t:gsub("\\","|") end)
	for i=1,#tags1 do
	    tag=tags1[i]
	    repeat tagz,c=tagz:gsub("|"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%1%2") until c==0
	    repeat tagz,c=tagz:gsub("\\"..tag.."[%d%.%-]+([^}]-)(\\"..tag.."[%d%.%-]+)","%2%1") until c==0
	end
	tagz=tagz:gsub("\\1c&","\\c&")
	for i=1,#tags2 do
	    tag=tags2[i]
	    repeat tagz,c=tagz:gsub("|"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%1%2") until c==0
	    repeat tagz,c=tagz:gsub("\\"..tag.."&H%x+&([^}]-)(\\"..tag.."&H%x+&)","%2%1") until c==0
	end
	repeat tagz,c=tagz:gsub("\\fn[^\\}]+([^}]-)(\\fn[^\\}]+)","%2%1") until c==0
	tagz=tagz:gsub("(|i?clip%(%A-%))(.-)(\\i?clip%(%A-%))","%2%3")
	:gsub("(\\i?clip%b())(.-)(\\i?clip%b())",function(a,b,c)
	    if a:match("m") and c:match("m") or not a:match("m") and not c:match("m") then return b..c else return a..b..c end end)
	tagz=tagz:gsub("|","\\"):gsub("\\t%([^\\%)]-%)","")
	return tagz
end

function extrakill(text,o)
	for i=1,#tags3 do
	    tag=tags3[i]
	    if o==2 then
	    repeat text,c=text:gsub("(\\"..tag.."[^\\}]+)([^}]-)(\\"..tag.."[^\\}]+)","%3%2") until c==0
	    else
	    repeat text,c=text:gsub("(\\"..tag.."[^\\}]+)([^}]-)(\\"..tag.."[^\\}]+)","%1%2") until c==0
	    end
	end
	repeat text,c=text:gsub("(\\pos[^\\}]+)([^}]-)(\\move[^\\}]+)","%1%2") until c==0
	repeat text,c=text:gsub("(\\move[^\\}]+)([^}]-)(\\pos[^\\}]+)","%1%2") until c==0
	return text
end

function progress(msg)
  if aegisub.progress.is_cancelled() then ak() end
  aegisub.progress.title(msg)
end

function t_error(message,cancel)
  ADD({{class="label",label=message}},{"OK"},{close='OK'})
  if cancel then ak() end
end

function logg(m) m=tf(m) or "nil" aegisub.log("\n "..m) end

function info(subs)
    for i=1,#subs do
      if subs[i].class=="info" then
	    local k=subs[i].key
	    local v=subs[i].value
	    if k=="PlayResX" then resx=v end
	    if k=="PlayResY" then resy=v end
      end
      if subs[i].class=="dialogue" then break end
    end
end


-- The Typesetter's Guide to the Hyperdimensional Relocator.
intro=[[
Introduction

Hyperdimensional Relocator offers a plethora of functions,
focusing primarily on \pos, \move, \org, \clip, and rotations.
Anything related to positioning, movement, changing shape, etc.,
Relocator aims to make it happen.

]].."Current version: "..script_version.."\n\nUpdate location:\n"..script_url

cannon=[[
'Align X' means all selected \pos tags will have the same given X coordinate. Same with 'Align Y' for Y.
   Useful for aligning multiple signs horizontally/vertically or mocha signs that should move horizontally/vertically.
   'by first' aligns by X or Y from the first line.

Horizontal Mirror: Duplicates the line and places it horizontally across the screen, mirrored around the middle.
   If you input a number, it will mirror around that coordinate instead,
   so if you have \pos(300,200) and input is 400, the mirrored result will be \pos(500,200).
   'keep both' will keep the original line along with the mirrored one. 'rotate' will flip the text accordingly.
Vertical Mirror is the logical vertical counterpart. 

Shake: Apply to fbf lines with \pos tags to create a shaking effect.
   Input radius for how many pixels the sign may deflect from the original position.
   (Use Teleporter coordinates if you want different values for X and Y.)
   'scaling' randomizes fscx/y. Value '6 'with fscx150 -> 144-156. (Uses input from the Force field.)
   'rotate' adds shaking to \frz (pos input, degrees). 'smooth' will make shaking smoother.
   'layers' will keep position/rotations the same for all layers. (Same value for same start time.)

Shake Rotation: Adds shaking effect to rotations. Degrees for frz from Repositioning Field, X/Y from Teleporter.

Shadow Layer: Creates shadow as a new layer. For offset, it uses in this order of priority:
   1. value from Positron or Teleporter (xshad, yshad). 2. shadow value from the line. 3. shadow from style.
   
Space Out Letters: Set a distance, and line will be split into letters with that distance between them.
   Value 1 = regular distance (only split). You can randomly expect about 1% inaccuracy.
   With a rectangular clip, the script tries to fit the text from side to side of the clip.
   fscx is supported, fs isn't, nor are rotations, move, linebreaks, and other things. Inline tags should work.

fbf X <--> Y: The fbf increase/decrease in pos X will become that of pos Y and vice versa.
   If 'by first' is checked, the first line is the reference line (won't change). Otherwise, it's the last line.
   With 'rotate' checked, the resulting direction is reversed. (Recalculator's Mirror adds more options to this.)
   Example: If a sign moves 100 pixels to the right, with 'first' it will move 100px down (or up with 'rotate').
   Without 'first', the directions are the same, but sign will end where it did before, not start.]]

clipthings=[[
Org to Fax: Calculates \fax from the line between \pos and \org coordinates.

Clip to Fax: Calculates \fax from the line between the first 2 points of a vectorial clip.
   Both of these work with \fscx, \fscy, and \frz.
   If the clip has 4 points, points 3-4 are used to calculate fax for the last character, and a gradient is applied.
   See blog post for more info - http://unanimated.xtreemhost.com/itw/tsblok.htm#fax

Clip to Frz: Calculates \frz from the first 2 points of a vectorial clip. Direction of text is from point 1 to point 2.
   If the clip has 4 points, the frz is average from 1-2 and 3-4. (Both lines must be in the same direction.)
   This helps when the sign is in the middle of a rectangular area where the top and bottom lines converge.

Clip to Reposition: Shifts \pos based on first 2 points of a vectorial clip.
   You can use a reference point in the video image and set the clip points at start/end of the movement.
   This may help when you want to "track" 2-3 frames and don't want to open Mocha for that.]]

replika=[[
Create replicas of selected lines positioned over specified distances.
'Replicas' is how many replicas of each line you'll make.
Distances for 'one replica':
	sets distances between two consecutive lines.
In this mode, distances are always relative, and formation curve is 1.
Distances for 'last replica':
	distance/coordinates for last replica.
'relative' distance is from the original.
'absolute' distance is video coordinates.
(This way all selected lines can replicate towards the same point.)
'formation curve' is acceleration for X and Y, if 'last replica' selected.
'use \move for last replica coordinates':
	target coordinates are taken from \move tag for each line.
This overrides 'one replica' mode.
All selected lines must have a \move tag. If not checked,
lines can still have \move, and all coordinates will be shifted.
'Delay' is by how many frames each replica will be shifted,
if you want them to appear one by one over time.
'keep end' will keep end time for such replicas same as the original.
Otherwise it gets shifted along with start time.
Should the end time be lower than start time, duration will be 1 frame.
(You should prevent this from happening as it makes no sense.)]]

fbfretrack=[[
There is simple mode and 'smoothen track' mode.

Simple mode is like fbf-transform for position, but it can be applied to several layers at the same time
and have different accel for X and Y.
If you check 'layers', the scale is not by selection but by start time.
You can have subtitles sorted by layers, but each layer must be sorted by time.
Of course each frame will have the same position for all layers/signs.
You can use Repositioning Field for accel, or Teleporter for separate X/Y accel.
Without 'layers' checked, it simply goes through selected lines and can be applied to signs in the same frame.

'Smoothen track' mode is activated when you check 'smooth'.
This is designed for smoothening tracking data,
i.e. it will move positions that stand out closer to the main line of the track.
It would make no sense to apply this to shaking signs, but if you have trouble tracking something in mocha
and the sign tends to jump off on some frames, this will pull the jumps back in line.
You can apply different strength of smoothening, by using the Force Field.
0 is the lowest strength; 100 is the highest and will make the track a straight line.]]

travel=[[
'Horizontal' move means Y2 will be the same as Y1 so that the sign moves in a straight horizontal manner.
Same principle for 'vertical.'

Multimove: When first line has \move and the others have \pos, \move for them is calculated from the first one.

Clip2move*: Move is calculated from first 2 points of a vectorial clip. Works for \pos, or adjusts \move.

Shiftmove*: Like teleporter, but only for the 2nd set of coordinates, ie. X2 and Y2. Uses input from Teleporter.
   'current frame' sets -end- timecode to current frame

Shiftstart: Similarly, this only shifts the initial \move coordinates.
   'current frame' sets -start- timecode to current frame

Reverse Move: Switches the coordinates, reversing the movement direction.

Move to*: Teleporter input sets target coordinats for \move for all selected lines.
   'current frame' sets end timecode to current frame

Move Clip: Moves regular clip along with \move using \t\clip.

*'times' will add timecodes to \move for these functions]]

transmoo=[[
Transmove*
Main function: create \move from two lines with \pos.
Duplicate your line, and position the second one where you want the \move the end.
Script will create \move from the two positions.
Second line will be deleted by default; it's there just so you can comfortably set the final position.
Extra function: to make this a lot more awesome, this can create transforms.
The second line is used not only for \move coordinates but also for transforms.
Any tag on line 2 that's different from line 1 will be used to create a transform on line 1.
So for a \move with transforms, you can set the initial sign and then the final sign while everything is static.
You can time line 2 to just the last frame. The script only uses timecodes from line 1.
Text from line 2 is also ignored (assumed to be same as line 1).
You can time line 2 to start after line 1 and check 'keep both.'
That way line 1 transforms into line 2, and the sign stays like that for the duration of line 2.
'Rotation acceleration' - like with fbf-transform, this ensures that transforms of rotations will go the shortest way,
thus going only 4 degrees from 358 to 2 and not 356 degrees around.
If the \pos is the same on both lines, only transforms will be applied.
Logically, you must NOT select 2 consecutive lines when you want to run this,
though you can select every other line.

'times' will add timecodes to \move]]

morph=[[
Round Numbers: rounds coordinates for pos, move, org and clip depending on the 'Round' submenu.

Joinfbflines: Select frame-by-frame lines, input number X into Force Field, and each X lines will be joined.
   (same way as with 'Join (keep first)' from the right-click menu)

KillMoveTimes: nukes timecodes from a \move tag.
KillTransTimes: nukes timecodes from \t tags.
FullMoveTimes: sets timecodes for \move to the first and last frame.
FullTransTimes: sets timecodes for \t to the first and last frame.

Move V. Clip: Moves vectorial clip on fbf lines based on \pos tags.
   Note: For decimals on v-clip coordinates: xy-vsfilter OK; libass rounds them; regular vsfilter fails completely.

Set Origin: set \org based off of \pos using Teleporter coordinates. (Shifts it by that much from \pos.)

Set Rotation: adds selected rotation tags with the value from the 'rotation' menu.
   (You can get multiples of 30 using the Aegisub tool while holding Ctrl.)

Rotate 180: rotates text by 180 degrees from current values of selected rotations (frx, fry, frz).

Negative rot: keeps the same rotation, but changes to negative number (350 -> -10), which helps with transforms.

Vector2rect/Rect.2vector: converts between rectangular and vectorial clips.

Clip Scale: Use Force field to set the X factor in "clip(X,m ", and the clip will be recalculated accordingly.

Find Centre: A useless function that sets \pos in the centre of a rectangular clip.

Randomize: randomizes values of given tags. With \fs50 and value 4 you can get fs 46-54.
   For regular tags, you can input multiple ones with commas between them.

Letterbreak: creates vertical text by putting a linebreak after each letter.
Wordbreak: replaces spaces with linebreaks.]]

morph2fbf=[[
Line2fbf:

Splits a line frame by frame, ie. makes a line for each frame.
If there's \move, it calculates \pos tags for each line.
If there are transforms, it calculates values for each line.
It should deal with all transforms, including inline tags and acceleration.
Move and transforms can have timecodes. (Though some calculations may end up about 1% off.)
\fad is supported too, but may not be entirely accurate with complex alphas.
Very complex lines with multiple transforms are likely to break in some way.

'clip2fbf' - clips will be shifted along with \move. (Don't use with clip transforms.)]]

morphorg=[[
Calculate Origin:

This calculates \org from a tetragonal vectorial clip you draw.
Draw a vectorial clip with 4 points, aligned to a surface you need to put your sign on.
The script will calculate the vanishing points for X and Y and give you \org.
Make the clip as large as you can, since on a smaller one any inaccuracies will be more obvious.
If you draw it well enough, the accuracy of the \org point should be pretty decent.
(It won't work when both points on one side are lower than both points on the other side.)
See this blog post for more details: http://unanimated.xtreemhost.com/itw/tsblok.htm#origin
]]

morphclip=[[
Transform Clip:

Go from \clip(x1,y1,x2,y2) to \clip(x1,y1,x2,y2)\t(\clip(x3,y3,x4,y4)).
Coordinates are read from the line.
You can set by how much x and y should change, and new coordinates will be calculated.

'use next line's clip' allows you to use clip from the next line.
   Create a line after your current one (or just duplicate), set the clip you want to transform to on it,
   and check 'use next line's clip'.
   The clip from the next line will be used for the transform, and the line will be deleted.]]

morphmasks=[[
Extend Mask: Use Teleporter X and Y fields to extend a mask in either or both directions.
   This is mainly intended to easily convert something like a rounded square to another rounded rectangle.
   Works optimally with a 0,0 coordinate in the centre. May do weird things with curves.
   When all coordinates are to one side from 0,0, then this works like shifting.
   
Flip mask: Flips a mask so that when used with its non-flipped counterpart, they create hollow space.
   For example you have a rounded square. Duplicate it, extend one by 10 pixels in each direction, flip it,
   and then merge them. You'll get a 10 px outline.

Adjust Drawing: (You must not have an unrelated clip in the line.)
   1. Creates a clip that copies the drawing.
   2. You adjust points with clip tool.
   3. Applies new coordinates to the drawing.

Randomask: Moves points in a drawing, each in a random direction, by a factor taken from the Force field.]]

cloan=[[
This copies specified tags from first line to the others.
Options are position, move, origin point, clip, and rotations.

replicate missing tags: creates tags if they're not present

stack clips: allows stacking of 1 normal and 1 vector clip in one line

match type: if current clip/iclip doesn't match the first line, it will be switched to match

combine vectors: if the first line has a vector clip, then for all other lines with vector clips
   the vectors will be combined into 1 clip

copy rotations: copies all rotations]]

port=[[
Teleport shifts coordinates for selected tags (\pos\move\org\clip) by given X and Y values.
It's a simple but powerful tool that allows you to move whole gradients, mocha-tracked signs, etc.

Note that the Teleporter fields are also used for some other functions, like Shiftstart and Shiftmove.
These functions don't use the 'Teleportation' button but the one for whatever part of HR they belong to.

'mod' allows you to add an extra factor applied line by line.
For example if you set '5' for 'X', things will shift by extra 5 pixels for each new line.

c1 and c2 control whether Teleportation affects top left and/or bottom right corner of a rectangular clip.
This means that for both X and Y, you can move either one or both sides of the clip.

'exp' means a rectangular clip won't be moved but expanded. X 10 means the clip will expand by 10
to the left and right. This ignores the c1/c2 settings.]]

function guide()
stg_top={x=0,y=0,class="label",
label="The Typesetter's Guide to the Hyperdimensional Relocator.                                                           "}

stg_toptop={x=1,y=0,class="label",label="Choose topic below."}
stg_topos={x=1,y=0,class="label",label="  Repositioning Field"}
stg_toptra={x=1,y=0,class="label",label="          Soul Bilocator"}
stg_toporph={x=1,y=0,class="label",label="   Morphing Grounds"}
stg_topseq={x=1,y=0,class="label",label="   Cloning Laboratory"}
stg_toport={x=1,y=0,class="label",label="           Teleportation"}

stg_intro={x=0,y=1,width=2,height=9,class="textbox",name="gd",value=intro}
stg_cannon={x=0,y=1,width=2,height=19,class="textbox",name="gd",value=cannon}
stg_can_to_things={x=0,y=1,width=2,height=10,class="textbox",name="gd",value=clipthings}
stg_replicate={x=0,y=1,width=2,height=14,class="textbox",name="gd",value=replika}
stg_retrack={x=0,y=1,width=2,height=12,class="textbox",name="gd",value=fbfretrack}
stg_travel={x=0,y=1,width=2,height=13,class="textbox",name="gd",value=travel}
stg_transmove={x=0,y=1,width=2,height=13,class="textbox",name="gd",value=transmoo}
stg_morph={x=0,y=1,width=2,height=20,class="textbox",name="gd",value=morph}
stg_morph2fbf={x=0,y=1,width=2,height=8,class="textbox",name="gd",value=morph2fbf}
stg_morphorg={x=0,y=1,width=2,height=8,class="textbox",name="gd",value=morphorg}
stg_morphclip={x=0,y=1,width=2,height=8,class="textbox",name="gd",value=morphclip}
stg_morpmsk={x=0,y=1,width=2,height=10,class="textbox",name="gd",value=morphmasks}
stg_cloan={x=0,y=1,width=2,height=9,class="textbox",name="gd",value=cloan}
stg_port={x=0,y=1,width=2,height=9,class="textbox",name="gd",value=port}

cp_main={"Positron Cannon","Hyperspace Travel","Metamorphosis","Cloning Sequence","Teleportation","Disintegrate"}
cp_back={"Warp Back"}
cp_cannon={"Warp Back","Positron Cannon","org/clip to Things","Replicate","FBF Retrack"}
cp_travel={"Warp Back","Hyperspace Travel","Transmove"}
cp_morph={"Warp Back","Metamorphosis","Line2fbf","Calculate Origin","Transform Clip","Masks/drawings"}
esk1={close='Disintegrate'}
esk2={cancel='Warp Back'}
stg={stg_top,stg_toptop,stg_intro} control_panel=cp_main esk=esk1
repeat
	stg={stg_top,stg_toptop,stg_intro} control_panel=cp_main esk=esk1
	if press=="Positron Cannon" then 	stg={stg_top,stg_topos,stg_cannon} control_panel=cp_cannon esk=esk2 end
	if press=="Hyperspace Travel" then 	stg={stg_top,stg_toptra,stg_travel} control_panel=cp_travel esk=esk2 end
	if press=="Metamorphosis" then 	stg={stg_top,stg_toporph,stg_morph} control_panel=cp_morph esk=esk2 end
	if press=="Cloning Sequence" then 	stg={stg_top,stg_topseq,stg_cloan} control_panel=cp_back esk=esk2 end
	if press=="Teleportation" then 	stg={stg_top,stg_toport,stg_port} control_panel=cp_back esk=esk2 end
	if press=="org/clip to Things" then 	stg={stg_top,stg_topos,stg_can_to_things} control_panel=cp_cannon esk=esk2 end
	if press=="Replicate" then 		stg={stg_top,stg_topos,stg_replicate} control_panel=cp_cannon esk=esk2 end
	if press=="FBF Retrack" then 		stg={stg_top,stg_topos,stg_retrack} control_panel=cp_cannon esk=esk2 end
	if press=="Transmove" then 		stg={stg_top,stg_topos,stg_transmove} control_panel=cp_travel esk=esk2 end
	if press=="Line2fbf" then 		stg={stg_top,stg_toporph,stg_morph2fbf} control_panel=cp_morph esk=esk2 end
	if press=="Calculate Origin" then 	stg={stg_top,stg_toporph,stg_morphorg} control_panel=cp_morph esk=esk2 end
	if press=="Transform Clip" then 	stg={stg_top,stg_toporph,stg_morphclip} control_panel=cp_morph esk=esk2 end
	if press=="Masks/drawings" then 		stg={stg_top,stg_toporph,stg_morpmsk} control_panel=cp_morph esk=esk2 end
	if press=="Warp Back" then 		stg={stg_top,stg_toptop,stg_intro} control_panel=cp_main esk=esk1 end
press,rez=ADD(stg,control_panel,esk)
until press=="Disintegrate"
if press=="Disintegrate" then ak() end
end


--	Config Stuff	--
function saveconfig()
hrconf="Hyperconfigator\n\n"
  for key,val in ipairs(hyperconfig) do
    if val.class=="floatedit" or val.class=="dropdown" then
      hrconf=hrconf..val.name..":"..res[val.name].."\n"
    end
    if val.class=="checkbox" and val.name~="save" then
      hrconf=hrconf..val.name..":"..tf(res[val.name]).."\n"
    end
  end
hyperkonfig=ADP("?user").."\\relocator.conf"
file=io.open(hyperkonfig,"w")
file:write(hrconf)
file:close()
ADD({{class="label",label="Config saved to:\n"..hyperkonfig}},{"OK"},{close='OK'})
end

function loadconfig()
rconfig=ADP("?user").."\\relocator.conf"
file=io.open(rconfig)
    if file~=nil then
	konf=file:read("*all")
	konf=konf:gsub("%-frz%-","rotation")
	io.close(file)
	for key,val in ipairs(hyperconfig) do
	    if val.class=="floatedit" or val.class=="checkbox" or val.class=="dropdown" then
	      if konf:match(val.name) then val.value=detf(konf:match(val.name..":(.-)\n")) end
	    end
	end
    end
end

function tf(val)
    if val==true then ret="true"
    elseif val==false then ret="false"
    else ret=val end
    return ret
end

function detf(txt)
    if txt=="true" then ret=true
    elseif txt=="false" then ret=false
    else ret=txt end
    return ret
end

function relocator(subs,sel,act)
ADD=aegisub.dialog.display
ADP=aegisub.decode_path
ak=aegisub.cancel
ms2fr=aegisub.frame_from_ms
fr2ms=aegisub.ms_from_frame
keyframes=aegisub.keyframes()
ATAG="{%*?\\[^}]-}"
STAG="^{\\[^}]-}"
rin=subs[act]	tk=rin.text
if tk:match"\\move%(" then 
m1,m2,m3,m4=tk:match("\\move%(([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)") M1=m3-m1 M2=m4-m2 mlbl=" mov: "..M1..","..M2
else mlbl="" end

Repositioning={"Align X","Align Y","org to fax","clip to fax","clip to frz","clip to reposition","horizontal mirror","vertical mirror","shake","shake rotation","shadow layer","space out letters","fbf X <--> Y","replicate","fbf retrack"}
Bilocator={"transmove","horizontal","vertical","multimove","clip2move","rvrs. move","shiftstart","shiftmove","move to","move clip","randomove"}
Morphing={"round numbers","line2fbf","join fbf lines","killmovetimes","killtranstimes","fullmovetimes","fulltranstimes","move v. clip","set origin","calculate origin","transform clip","set rotation","rotate 180","negative rot","vector2rect.","rect.2vector","clip scale","find centre","extend mask","flip mask","adjust drawing","randomask","randomize...","letterbreak","wordbreak"}
Rounding={"all","pos","move","org","clip","mask"}
Freezing={"rotation","5","10","20","45","70","110","135","160","-5","-10","-20","-45","-70","-110","-135","-160"}
noneg="\\bord\\shad\\xbord\\ybord\\fs\\blur\\be\\fscx\\fscy"

hyperconfig={
    {x=12,y=0,width=2,class="label",label="Teleportation"},
    {x=12,y=1,width=3,class="floatedit",name="eks",hint="X"},
    {x=12,y=2,width=3,class="floatedit",name="wai",hint="Y"},

    {x=0,y=0,width=3,class="label",label="Repositioning Field"},
    {x=0,y=1,width=2,class="dropdown",name="posi",value="clip to frz",items=Repositioning},
    {x=0,y=2,width=2,class="floatedit",name="post",value=0},
    {x=0,y=3,class="checkbox",name="first",label="by first",value=true,hint="align with first line"},
    {x=1,y=3,class="checkbox",name="rota",label="rotate",hint="shake rotation / rotate mirrors"},
    {x=0,y=4,class="checkbox",name="layers",label="layers",value=true,hint="synchronize shaking for all layers"},
    {x=1,y=4,class="checkbox",name="smo",label="smooth",hint="smoothen shaking"},
    {x=1,y=5,class="checkbox",name="sca",label="scaling",hint="add scaling to shake"},
    {x=0,y=6,class="label",label="      Force:"},
    {x=1,y=6,width=3,class="floatedit",name="force",value=0,hint="shake: scaling value\nfbf retrack: smoothening force\njoin fbf lines: # of lines\nclip scale: scale factor\nrandomask: randomness factor"},

    {x=3,y=0,width=3,class="label",label="Soul Bilocator"},
    {x=3,y=1,width=2,class="dropdown",name="move",value="transmove",items=Bilocator},
    {x=3,y=2,width=2,class="checkbox",name="keep",label="keep both",hint="keeps both lines for transmove/mirrors"},
    {x=3,y=3,width=4,class="checkbox",name="rotac",label="rotation acceleration",value=true,hint="transmove option"},
    {x=3,y=4,width=1,class="checkbox",name="times",label="times",hint="set \\move times"},
    {x=3,y=5,width=3,class="checkbox",name="videofr",label="current frame",hint="set relevant timecode\nto current frame\n(shiftstart, shiftmove)"},
    
    {x=6,y=0,width=2,class="label",label="Morphing Grounds"},
    {x=6,y=1,width=2,class="dropdown",name="mod",value="round numbers",items=Morphing},
    {x=6,y=2,class="label",label="round:"},
    {x=7,y=2,class="dropdown",name="rnd",items=Rounding,value="all"},
    {x=7,y=3,class="dropdown",name="rndec",items={"1","0.1","0.01","0.001"},value="1",hint="rounding"},
    {x=7,y=4,class="dropdown",name="freeze",items=Freezing,value="rotation"},
    {x=6,y=6,width=2,class="checkbox",name="delfbf",label="delete orig. line",value=true,hint="delete original line for line2fbf"},
    {x=7,y=7,width=1,class="checkbox",name="c2fbf",label="clip2fbf",value=true,hint="line2fbf: shift clip along with \\move"},
    {x=6,y=4,width=1,class="checkbox",name="frz",label="frz",value=true,hint=""},
    {x=6,y=5,width=1,class="checkbox",name="frx",label="frx",hint=""},
    {x=7,y=5,width=1,class="checkbox",name="fry",label="fry",hint=""},

    {x=8,y=0,width=3,class="label",label="Cloning Laboratory"},
    {x=8,y=1,width=2,class="checkbox",name="cpos",label="\\posimove",value=true},
    {x=10,y=1,class="checkbox",name="corg",label="\\org",value=true},
    {x=8,y=2,class="checkbox",name="cclip",label="\\[i]clip",value=true},
    {x=9,y=2,width=2,class="checkbox",name="ctclip",label="\\t(\\[i]clip)",value=true},
    {x=8,y=6,width=4,class="checkbox",name="cre",label="replicate missing tags",value=true},
    {x=8,y=3,width=2,class="checkbox",name="stack",label="stack clips"},
    {x=8,y=5,width=3,class="checkbox",name="copyrot",label="copy rotations"},
    {x=10,y=3,width=3,class="checkbox",name="klipmatch",label="match type    "},
    {x=8,y=4,width=3,class="checkbox",name="combine",label="combine vectors"},

    {x=13,y=3,class="checkbox",name="tppos",label="pos",value=true},
    {x=13,y=4,class="checkbox",name="tpmov",label="move",value=true},
    {x=14,y=3,class="checkbox",name="tporg",label="org",value=true},
    {x=14,y=4,class="checkbox",name="tpclip",label="clip",value=true},
    {x=12,y=4,class="checkbox",name="tpc1",label="c1",value=true,hint="affect top left corner of rectangular clip"},
    {x=12,y=5,class="checkbox",name="tpc2",label="c2",value=true,hint="affect bottom right corner of rectangular clip"},
    {x=14,y=5,class="checkbox",name="tpexp",label="exp",hint="expand rectangular clip in opposite directions"},
    {x=13,y=5,class="checkbox",name="tpmask",label="mask"},
    {x=14,y=0,class="checkbox",name="tpmod",label="mod"},
    {x=12,y=6,width=3,class="checkbox",name="autopos",label="pos with tags missing",value=true,hint="Teleport position when \\pos tags missing"},

    {x=0,y=7,width=3,class="checkbox",name="space",label="SpaceTravel Guide",
	hint="The Typesetter's Guide to the Hyperdimensional Relocator."},
    {x=3,y=7,width=4,class="label",name="moo",label=mlbl},
    {x=8,y=7,width=2,class="checkbox",name="rpt",label="Repeat",hint="Repeat with last settings (any function)"},
    {x=10,y=7,width=3,class="checkbox",name="save",label="Save config",hint="Save current configuration"},
    {x=13,y=7,width=2,class="label",label="<Incarnation "..script_version..">"}
}
	loadconfig()
	if remember then
	  for key,val in ipairs(hyperconfig) do
	    if val.name=="posi" then val.value=lastpos end
	    if val.name=="move" then val.value=lastmove end
	    if val.name=="mod" then val.value=lastmod end
	  end
	end
	P,res=ADD(hyperconfig,
	{"Positron Cannon","Hyperspace Travel","Metamorphosis","Cloning Sequence","Teleportation","Disintegrate"},{cancel='Disintegrate'})
	if P=="Disintegrate" then ak() end
	
	if imprint and res.rpt then res=imprint end
	remember=true	imprint=res
	lastpos=res.posi	lastmove=res.move	lastmod=res.mod
	if res.save then saveconfig() ak() end
	
	if P=="Positron Cannon" then if res.space then guide(subs,sel) else sel=positron(subs,sel) end end
	if P=="Hyperspace Travel" then
	    if res.move=="multimove" then multimove (subs,sel)
	    elseif res.move=="randomove" then randomove (subs,sel)
	    else bilocator(subs,sel) end
	end
	if P=="Metamorphosis" then
	    aegisub.progress.title(string.format("Morphing..."))
	    if res.mod=="line2fbf" then sel=movetofbf(subs,sel)
	    elseif res.mod=="transform clip" then transclip(subs,sel,act)
	    elseif res.mod=="join fbf lines" then joinfbflines(subs,sel)
	    else modifier(subs,sel) end
	end
	if P=="Cloning Sequence" then clone(subs,sel) end
	if P=="Teleportation" then teleport(subs,sel) end
    aegisub.set_undo_point(script_name)
    return sel
end

if haveDepCtrl then depRec:registerMacro(relocator) else aegisub.register_macro(script_name,script_description,relocator) end