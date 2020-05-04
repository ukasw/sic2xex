program SIC2XEX;
uses
 crt;

var
 infile, outfile: file of byte;
 intro_flag: Boolean = false;
 xex_size: dword = 0;
 xex_cnt: byte = 0; // how many files on list
 i, j: integer;
 k: dword;
 buf: byte;
 names_tab: array[0..255] of string;
 address_tab: array[0..255] of dword;
 sizes_tab: array[0..255] of dword;

function adress_to_hex_string(addres: dword): string;
var
 addr0, addr1, addr2, addr3: byte;
const
 hexstr: string = '0123456789ABCDEF'; 
begin
 addr3:= addres div 65536;
 addres:= addres - addr3*65536; 
 addr2:= addres div 4096;
 addres:= addres - addr2*4096;
 addr1:= addres div 256;
 addres:= addres - addr1*256;
 addr0:= addres div 16;
 addres:= addres - addr0*16;
 adress_to_hex_string:= hexstr[addr3+1]+hexstr[addr2+1]+hexstr[addr1+1]+hexstr[addr0+1]+hexstr[addres+1];
end;

procedure chun_li;
var
 num: byte;
begin
 randomize;
 num:=random(8);
 case num of
  0: writeln('Don''t worry. I didn''t damage anything permanently, I think.');
  1: writeln('Fighting ability is important... handcuffs only go so far!');
  2: writeln('I need a vacation! Being an inspector isn''t easy!');
  3: writeln('I''m just doing my duty... Please don''t take it personally!');
  4: writeln('My strength must have been something you weren''t ready for!');
  5: writeln('Oops! I''m sorry if I hit you there too hard!');
  6: writeln('So, do you have anything to say in your defense?');
  7: writeln('Speed is something more important than strength!');
 end;
 halt(0);
end;

procedure help_msg(flag: boolean);
begin
 writeln('usage: sic2xex <input filename>');
 writeln;
 if (flag = true) then
  halt(1);
end; 

procedure error_msg(error_num: byte);
begin
 case error_num of
  0: writeln('error: input filename required');
  1: writeln('error: too many parameters');
  2: writeln('error: no such file or directory');
  3: writeln('error: invalid input file');
  4: writeln('error: K.O.');
 end;
 help_msg(false);
 chun_li;
end;

procedure check_input_file(const infile_name: string);
var
 infile_type, hex_addres: string;
 offset, bank: byte;
const
 bin512_chck_size: dword = 524288;
 bin256_chck_size: dword = 262144;
 bin128_chck_size: dword = 131072;
 atascii: string = '!"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_                                 abcdefghijklmnopqrstuvwxyz      ';        
begin
 {$i-}
 writeln('loading file: ',infile_name);
 assign(infile, infile_name);
 reset(infile);
 if IOResult<>0 then
  error_msg(2);
 
 // check size
 infile_type:= '-';
 if(FileSize(infile) = bin512_chck_size)then
  infile_type:= '512kb';
 if(FileSize(infile) = bin256_chck_size)then
  infile_type:= '256kb';
 if(FileSize(infile) = bin128_chck_size)then
  infile_type:= '128kb';
  
 if(infile_type <> '-')then
 begin
  writeln('file size: ',FileSize(infile),' bytes (',infile_type,' chip)');
 end
 else begin
  write('file size: ',FileSize(infile),' bytes');
  close(infile);
  error_msg(3);
 end;
 
 // check header 
 seek(infile, 1);
 read(infile, buf);
 
 if(buf = 1)then
 begin
  intro_flag:= true;
  writeln('found intro file');
  
  // get size of intro
  seek(infile, 16384);
  repeat
   read(infile, buf);
   if(buf = 254)then
   begin
    read(infile, buf);
    if(buf = 255)then
    begin
     read(infile, buf);
     if(buf = 0) then
     begin
      xex_size:= filepos(infile)-16387;
     end;
    end;
   end;
  until xex_size <> 0;
  writeln('->0x', adress_to_hex_string(16384), ' ', xex_size, 'b');
 end;
 
 seek(infile, 25);
 read(infile, xex_cnt);

 write('found ');
 write(xex_cnt);
 if((xex_cnt > 1) or (xex_cnt = 0))then
   writeln(' files:')
 else
   writeln(' file:');
 
 // get data about xex files
 if(xex_cnt > 0)then
 begin
  seek(infile, 64);
  for i:=0 to xex_cnt-1 do
  begin
   read(infile, offset);
   read(infile, bank);
   address_tab[i]:= 16384*bank+offset*256;
   for k:=0 to 24 do 
   begin
    read(infile, buf);
    if(buf = 255)then begin
      for j:=k+1 to 24 do
       read(infile, buf);
      break;
    end;

    if(buf < 129)then
    begin
     if(buf <> 0)then
      names_tab[i]:= names_tab[i]+atascii[buf]
     else
      names_tab[i]:= names_tab[i]+' ';
    end;     
   end;
   read(infile, buf); // $ff
   read(infile, buf); // $00
   read(infile, buf);
   sizes_tab[i]:= buf;
   read(infile, buf);
   sizes_tab[i]:= sizes_tab[i]+buf*256;
   read(infile, buf);
   sizes_tab[i]:= sizes_tab[i]+buf*65536;

   writeln('->0x', adress_to_hex_string(address_tab[i]), ' ', sizes_tab[i], 'b ', names_tab[i]);
  end;
 end;
 {$i+}
end;

procedure save_xex_files;
begin
 {$i-}
 if(intro_flag = true)then
 begin
  // save xex intro file
  assign(outfile, 'intro.xex');
  rewrite(outfile);
  
  if IOResult<>0 then
   error_msg(4);
  
  seek(infile, 16384);  
  
  for k:=1 to xex_size do
  begin
   read(infile, buf);
   write(outfile, buf);
  end;  

  writeln('saving xex file: intro.xex');
  close(outfile);
 end;
 
 // save xex files
 for i:=0 to xex_cnt-1 do
 begin
  seek(infile, address_tab[i]);
  
  // create new xex file
  for j:=1 to length(names_tab[i]) do
  begin
   // windows dont like ?/\<>*:" symbols in filenames..
   if ((names_tab[i][j] = '?') or (names_tab[i][j] = '/') or (names_tab[i][j] = '\') or (names_tab[i][j] = '*') or (names_tab[i][j] = ':') or (names_tab[i][j] = '<') or (names_tab[i][j] = '>') or (names_tab[i][j] = '"'))then
    // ..so put there space
    names_tab[i][j]:= ' ';
  end;  

  assign(outfile, names_tab[i]+'.xex');
  rewrite(outfile);
 
  if IOResult<>0 then
   error_msg(4);

  for k:=1 to sizes_tab[i] do
  begin
   read(infile, buf);
   write(outfile, buf);
  end;  
  writeln('saving XEX file: ', names_tab[i], '.xex');
  close(outfile);
 end;
 {$i+}
end;

begin
 {$i-}
 if (ParamCount < 1)then 
  error_msg(0);
	
 if (ParamCount > 1)then 
  error_msg(1); 
 
 if((ParamStr(1) = '-h')or(ParamStr(1) = '-help' )or(ParamStr(1) = '--help'))then
  help_msg(true)
 else
  // params ok try open file
  check_input_file(ParamStr(1));

 // save xex files from menu list
 save_xex_files();
 {$i+}
end.
