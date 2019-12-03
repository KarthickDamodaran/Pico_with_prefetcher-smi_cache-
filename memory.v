`timescale 1 ns / 1 ps
module mem(clk,mem_valid,mem_instr,mem_ready,mem_addr1,mem_wdata,mem_wstrb,mem_rdata);
input clk;
input mem_valid;
	input mem_instr;
	output reg mem_ready;
	input [31:0] mem_addr1;
	input [31:0] mem_wdata;
	input [3:0] mem_wstrb;
	output reg [31:0] mem_rdata;
reg [31:0]memory[0:255];
reg [31:0] mem_addr;
reg [31:0]data_n,mem_data;
reg [dataSize:0]data1,data2,data3,data4;
//input clk;
reg [31:0]address;
//tag-21 bits, index-3 bits, block id-2 bits, offset-6 bits
parameter dataSize=31; //64 bytes. Each byte is 8 bits each 64*8=512 bits
//parameter way=7;
parameter set=63;
parameter SBtagsize=25;
//Superblock: tag-5 bits [24:4],block_id-4 bits[3:0]
parameter pref_size=7;
parameter pref_blocks=4;
//Prefetecher is fully associative with 8 ways and single index. Each way has 4 blocks of data.

reg [SBtagsize:0]tagArray[set:0];
reg [dataSize:0]dataArray[set:0];
//reg [2:0]lruShiftReg[set:0][way:0];
reg [9:0] LRU_cache_count[set:0];
reg pref_mem_ready,cache_mem_ready;

reg [127:0]prefetcher_data[0:0][pref_size:0]; // prefetcher declaration
reg [29:0]prefetcher_tag[0:0][pref_size:0];
reg pref_flag[31:0];
//integer counter[set:0][way:0];
reg ValidBit[7:0];
reg [6:0] LRU_prefetch_count[0:0][7:0];
reg [2:0] block_no;
reg [31:0]addr;
reg [63:0] valid;


reg foundDatainCache,foundDatainprefetcher;
reg [dataSize:0]data; //Data 

reg [1:0] CF;
reg [9:0] pref_cnt [0:0][31:0];

integer file_outputs; // var to see if file exists 
integer scan_outputs; // captured text handler
integer g;
integer cache_Hit=0,cache_Miss=0,prefetcher_Hit=0,Prefetcher_usage=0,Pref_in=0,pref_u=0,m;
integer count=0,enter=0;
initial begin
ValidBit[0]=0;
ValidBit[1]=0;
ValidBit[2]=0;
ValidBit[3]=0;
ValidBit[4]=0;
ValidBit[5]=0;
ValidBit[6]=0;
ValidBit[7]=0;
valid=0;
pref_mem_ready=0;cache_mem_ready=0;
for(m=0;m<32;m=m+1)
begin
pref_cnt[0][m]=10'd0;
end
end
/*initial begin
LRU_prefetch_count[0][0]=0;
LRU_prefetch_count[0][1]=0;
LRU_prefetch_count[0][2]=0;
LRU_prefetch_count[0][3]=0;
LRU_prefetch_count[0][4]=0;
LRU_prefetch_count[0][5]=0;
LRU_prefetch_count[0][6]=0;
LRU_prefetch_count[0][7]=0;
end*/
initial
begin
//open the data Memory file
valid=0;
$readmemh("PICOData.txt",memory);
end
always @ (posedge mem_ready)
begin
if(pref_mem_ready !=1 && cache_mem_ready!=1)
       UpdatePrefecther(address,data);
for(g=0; g<8; g=g+1)
begin
$display("location1:%h  location2:%h  location3:%h  location4:%h \n",prefetcher_data[0][g][127:96],prefetcher_data[0][g][95:64],prefetcher_data[0][g][63:32],prefetcher_data[0][g][31:0]);
end

      //findDataInPrefetcher1(address,foundDatainprefetcher,data);
end
always @(posedge clk) //Only when there is a change in the 
begin
mem_ready <= 0;
pref_mem_ready <=0;
cache_mem_ready<=0;
mem_addr=mem_addr1/4;
address = mem_addr1/4;
enter=enter+1;
foundDatainCache=0;foundDatainprefetcher=0;
$display($time,"  Address:%h",address);
findDataInCache(address,foundDatainCache,data);//task

if(foundDatainCache)
begin
//No need to go to memory and update cache or use LRU policy
//decompress the data and display 
//decompress();
cache_Hit=cache_Hit+1;
$display($time ,"  Cache HIT and data read=%h and  Number_Of_Cache_Hit=%d\n",mem_rdata,cache_Hit);
$display($time ,"  Number_Of_Cache_Hit=%d\n",cache_Hit);
$display($time ,"  Number_Of_Cache_miss=%d\n",cache_Miss);
$display($time ,"  Number_Of_Prefetcher_hit=%d\n",prefetcher_Hit);
$display($time ,"  Number_Of_Prefetcher_usage=%d\n",pref_u);
$display($time ,"  Number_Of_Prefetcher_Data_in=%d\n",Pref_in);
$display($time ,"  Number_Of_Prefetcher to cahce=%d\n",Prefetcher_usage);
end

else 
begin
//findDataInMemory(mem_addr,mem_data);
//$display("Data from first memory ref : %h, address : %h", mem_rdata, mem_addr);

      
    findDataInPrefetcher(address,foundDatainprefetcher,data);//task 

       if(foundDatainprefetcher)begin
	$display("Hit : %b, with Data : %h", foundDatainprefetcher, mem_rdata);
       prefetcher_Hit=prefetcher_Hit+1;
       $display($time ,"  Cache miss but hit in prefetcher and data read=%h \n",mem_rdata);
           $display($time ,"  Number_Of_Cache_Hit=%d\n",cache_Hit);
           $display($time ,"  Number_Of_Cache_miss=%d\n",cache_Miss);
           $display($time ,"  Number_Of_Prefetcher_hit=%d\n",prefetcher_Hit);
           $display($time ,"  Number_Of_Prefetcher_usage=%d\n",pref_u);
           $display($time ,"  Number_Of_Prefetcher_Data_in=%d\n",Pref_in);
           $display($time ,"  Number_Of_Prefetcher to cahce=%d\n",Prefetcher_usage);
       end
       
       else begin
//if(mem_ready==1)
  //     UpdatePrefecther(address,data);

    //  findDataInPrefetcher1(address,foundDatainprefetcher,data);
findDataInMemory(mem_addr,mem_data);//task
//compress();
//findCompFactor(data,CF);
//updateCache(address,data,CF); //YACC logic

//send uncompressed data to lower level cache
cache_Miss=cache_Miss+1;
$display($time ,"  Both Cache MISS and prefetcher miss. data read=%h \n",mem_rdata);
$display($time ,"  Number_Of_Cache_Hit=%d\n",cache_Hit);
        $display($time ,"  Number_Of_Cache_miss=%d\n",cache_Miss);
        $display($time ,"  Number_Of_Prefetcher_Hit=%d\n",prefetcher_Hit);
        $display($time ,"  Number_Of_Prefetcher_usage=%d\n",pref_u);
        $display($time ,"  Number_Of_Prefetcher_Data_in=%d\n",Pref_in);
        $display($time ,"  Number_Of_Prefetcher to cahce=%d\n",Prefetcher_usage);
end 	
end
//count=count+1;
end

//Task to find the data in cache
task findDataInCache;
input [31:0] address;
output foundDatainCache;
output[dataSize:0]data;
reg [5:0] index;
reg [25:0] tag;
integer i,j;
begin
$display("Entered cache");
tag=address[31:6];
index=address[5:0];
j=index;
$display("j=%d",j);
i=0;
foundDatainCache=0;

if(tagArray[index]==tag && valid[j])
foundDatainCache=1;

if(foundDatainCache==1)begin
mem_rdata=dataArray[index];
end
if(mem_valid==1 && foundDatainCache==1) 
begin
mem_ready<=1;cache_mem_ready<=1;
//pref_mem_ready<=1;
end
end
endtask

task findDataInPrefetcher; 
input [31:0]address;
output foundDatainprefetcher;
output [dataSize:0] data;
//reg [dataSize:0] data1,data2,data3,data4;
reg [29:0] tag1;
reg [1:0] blockID;
reg match;

integer j;
begin
$display("Entering prefetcher");
$display("Address=%h",address);
tag1=address[31:2];
blockID=address[1:0];
//$display($time,"  tag=%b  blockId=%b ",tag1,blockID);
j=0;
foundDatainprefetcher=0;
match=0;
while(j<=pref_size && !match) begin
if(tag1==prefetcher_tag[0][j]) begin
match=1;
foundDatainprefetcher=1;
//if(mem_valid==1) mem_ready<=1;
$display("Match found");
end
else begin
j=j+1;
end
end
if(mem_valid==1 && foundDatainprefetcher==1) 
begin
mem_ready<=1;
pref_mem_ready<=1;
end
if(match)begin
$display($time,"  tag=%b  blockId=%b ",tag1,blockID);
$display("j=%d ",j);
    case(j) 
    
        0: begin
        
        if(blockID==2'b00) begin
        data=prefetcher_data[0][0][127:96];
	mem_rdata<=prefetcher_data[0][0][127:96];
        pref_flag[0]=1;
        
        pref_cnt[0][0]=pref_cnt[0][0] + 1'b1;
        
        if(pref_cnt[0][0]==10'd1)
        begin
        pref_u=pref_u+1;
        end
        end
        
        else if(blockID==2'b01) begin
        data=prefetcher_data[0][0][95:64];
	mem_rdata<=prefetcher_data[0][0][95:64];
        pref_flag[1]=1;
        
        pref_cnt[0][1]=pref_cnt[0][1] + 1'b1;
                
                if(pref_cnt[0][1]==10'd1)
                begin
                pref_u=pref_u+1;
                end       
        end
        
        else if(blockID==2'b10) begin
        $display("enetered 10");
        data=prefetcher_data[0][0][63:32];
	mem_rdata<=prefetcher_data[0][0][63:32];
        pref_flag[2]=1;
        $display("Incrementing pref count 10");
        pref_cnt[0][2]=pref_cnt[0][2] + 1'b1;
                
                if(pref_cnt[0][2]==10'd1)
                begin
                $display("Incremented 10");
                pref_u=pref_u+1;
                end
        end
        
        else begin
        $display("enetered 11");
        data=prefetcher_data[0][0][31:0];
	mem_rdata<=prefetcher_data[0][0][31:0];
        pref_flag[3]=1;
        $display("Incrementing pref count 11");
        pref_cnt[0][3]=pref_cnt[0][3] + 1'b1;
                
                if(pref_cnt[0][3]==10'd1)
                begin
                $display("Incremented 11");
                pref_u=pref_u+1;
                end        
        end

        
        LRU_prefetch_count[0][j]=6'b111111;
        //$display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);
        end
        
        1: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][1][127:96];
	mem_rdata<=prefetcher_data[0][1][127:96];
        pref_flag[4]=1;
        
        pref_cnt[0][4]=pref_cnt[0][4] + 1'b1;
                
                if(pref_cnt[0][4]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][1][95:64];
	mem_rdata<=prefetcher_data[0][1][95:64];
        pref_flag[5]=1;
        
        pref_cnt[0][5]=pref_cnt[0][5] + 1'b1;
                
                if(pref_cnt[0][5]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][1][63:32];
	mem_rdata<=prefetcher_data[0][1][63:32];
        pref_flag[6]=1;
        
        pref_cnt[0][6]=pref_cnt[0][6] + 1'b1;
                
                if(pref_cnt[0][6]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][1][31:0];
	mem_rdata<=prefetcher_data[0][1][31:0];
        pref_flag[7]=1;
        pref_cnt[0][7]=pref_cnt[0][7] + 1'b1;
                
                if(pref_cnt[0][7]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);
        end
        
        2: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][2][127:96];
	mem_rdata<=prefetcher_data[0][2][127:96];
        pref_flag[8]=1;
        pref_cnt[0][8]=pref_cnt[0][8] + 1'b1;
                
                if(pref_cnt[0][8]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][2][95:64];
	mem_rdata<=prefetcher_data[0][2][95:64];
        pref_flag[9]=1;
        pref_cnt[0][9]=pref_cnt[0][9] + 1'b1;
                
                if(pref_cnt[0][9]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][2][63:32];
	mem_rdata<=prefetcher_data[0][2][63:32];
        pref_flag[10]=1;
        pref_cnt[0][10]=pref_cnt[0][10] + 1'b1;
                
                if(pref_cnt[0][10]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][2][31:0];
	mem_rdata<=prefetcher_data[0][2][31:0];
        pref_flag[11]=1;
        pref_cnt[0][11]=pref_cnt[0][11] + 1'b1;
                
                if(pref_cnt[0][11]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);
        end 
        
        3: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][3][127:96];
	mem_rdata<=prefetcher_data[0][3][127:96];
        pref_flag[12]=1;
        pref_cnt[0][12]=pref_cnt[0][12] + 1'b1;
                
                if(pref_cnt[0][12]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][3][95:64];
	mem_rdata<=prefetcher_data[0][3][95:64];
        pref_flag[13]=1;
        pref_cnt[0][13]=pref_cnt[0][13] + 1'b1;
                
                if(pref_cnt[0][13]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][3][63:32];
	mem_rdata<=prefetcher_data[0][3][63:32];
        pref_flag[14]=1;
        pref_cnt[0][14]=pref_cnt[0][14] + 1'b1;
                
                if(pref_cnt[0][14]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][3][31:0];
	mem_rdata<=prefetcher_data[0][3][31:0];
        pref_flag[15]=1;
        pref_cnt[0][15]=pref_cnt[0][15] + 1'b1;
                
                if(pref_cnt[0][15]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);
        end
        
        4: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][4][127:96];
	mem_rdata<=prefetcher_data[0][4][127:96];
        pref_flag[16]=1;
        pref_cnt[0][16]=pref_cnt[0][16] + 1'b1;
                
                if(pref_cnt[0][16]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][4][95:64];
	mem_rdata<=prefetcher_data[0][4][95:64];
        pref_flag[17]=1;
        pref_cnt[0][17]=pref_cnt[0][17] + 1'b1;
                
                if(pref_cnt[0][17]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][4][63:32];
	mem_rdata<=prefetcher_data[0][4][63:32];
        pref_flag[18]=1;
        pref_cnt[0][18]=pref_cnt[0][18] + 1'b1;
                
                if(pref_cnt[0][18]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][4][31:0];
	mem_rdata<=prefetcher_data[0][4][31:0];
        pref_flag[19]=1;
        pref_cnt[0][19]=pref_cnt[0][19] + 1'b1;
                
                if(pref_cnt[0][19]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);
        end
        
        5: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][5][127:96];
	mem_rdata<=prefetcher_data[0][5][127:96];
        pref_flag[20]=1;
        pref_cnt[0][20]=pref_cnt[0][20] + 1'b1;
                
                if(pref_cnt[0][20]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][5][95:64];
	mem_rdata<=prefetcher_data[0][5][95:64];
        pref_flag[21]=1;
        pref_cnt[0][21]=pref_cnt[0][21] + 1'b1;
                
                if(pref_cnt[0][21]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][5][63:32];
	mem_rdata<=prefetcher_data[0][5][63:32];
        pref_flag[22]=1;
        pref_cnt[0][22]=pref_cnt[0][22] + 1'b1;
                
                if(pref_cnt[0][22]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][5][31:0];
	mem_rdata<=prefetcher_data[0][5][31:0];
        pref_flag[23]=1;
        pref_cnt[0][23]=pref_cnt[0][23] + 1'b1;
                
                if(pref_cnt[0][23]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);;
        end 
        
        6: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][6][127:96];
	mem_rdata<=prefetcher_data[0][6][127:96];
        pref_flag[24]=1;
        pref_cnt[0][24]=pref_cnt[0][24] + 1'b1;
                
                if(pref_cnt[0][24]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][6][95:64];
	mem_rdata<=prefetcher_data[0][6][95:64];
        pref_flag[25]=1;
        pref_cnt[0][25]=pref_cnt[0][25] + 1'b1;
                
                if(pref_cnt[0][25]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][6][63:32];
	mem_rdata<=prefetcher_data[0][6][63:32];
        pref_flag[26]=1;
        pref_cnt[0][26]=pref_cnt[0][26] + 1'b1;
                
                if(pref_cnt[0][26]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][6][31:0];
	mem_rdata<=prefetcher_data[0][6][31:0];
        pref_flag[27]=1;
        pref_cnt[0][27]=pref_cnt[0][27] + 1'b1;
                
                if(pref_cnt[0][27]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);
        end     
 
        7: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][7][127:96];
	mem_rdata<=prefetcher_data[0][7][127:96];
        pref_flag[28]=1;
        pref_cnt[0][28]=pref_cnt[0][28] + 1'b1;
                
                if(pref_cnt[0][28]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][7][95:64];
	mem_rdata<=prefetcher_data[0][7][95:64];
        pref_flag[29]=1;
        pref_cnt[0][29]=pref_cnt[0][29] + 1'b1;
                
                if(pref_cnt[0][29]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][7][63:32];
	mem_rdata<=prefetcher_data[0][7][63:32];
        pref_flag[30]=1;
        pref_cnt[0][30]=pref_cnt[0][30] + 1'b1;
                $display("entered pref count");
                if(pref_cnt[0][30]==10'd1)
                begin
                pref_u=pref_u+1;
                $display("incremented");
                end
                
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][7][31:0];
	mem_rdata<=prefetcher_data[0][7][31:0];
        pref_flag[31]=1;
        pref_cnt[0][31]=pref_cnt[0][31] + 1'b1;
                
                if(pref_cnt[0][31]==10'd1)
                begin
                pref_u=pref_u+1;
                end
                
        end
        LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);
        end          
        
    endcase
end    

end
endtask

task findDataInPrefetcher1; 
input [31:0]address;
output foundDatainprefetcher;
output [dataSize:0] data;
//reg [dataSize:0] data1,data2,data3,data4;
reg [29:0] tag1;
reg [1:0] blockID;
reg match;

integer j;
begin
$display("Entering prefetcher again");
$display("Address=%h",address);
tag1=address[31:2];
blockID=address[1:0];
$display($time,"  tag=%b  blockId=%b ",tag1,blockID);
j=0;
foundDatainprefetcher=0;
match=0;
while(j<=pref_size && !match) begin
if(tag1==prefetcher_tag[0][j]) begin
match=1;
foundDatainprefetcher=1;
$display("Match found 2nd time");
end
else begin
j=j+1;
end
end

if(match)begin
    case(j) 
    
        0: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][0][127:96];
        pref_flag[0]=1;
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][0][95:64];
        pref_flag[1]=1;
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][0][63:32];
        pref_flag[2]=1;
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][0][31:0];
        pref_flag[3]=1;
        end
       /* LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j); */
        end
        
        1: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][1][127:96];
        pref_flag[4]=1;
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][1][95:64];
        pref_flag[5]=1;
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][1][63:32];
        pref_flag[6]=1;
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][1][31:0];
        pref_flag[7]=1;
        end
       /* LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j); */
        end
        
        2: begin
        if(blockID==00) begin
        data=prefetcher_data[0][2][127:96];
        pref_flag[8]=1;
        end
        if(blockID==01) begin
        data=prefetcher_data[0][2][95:64];
        pref_flag[9]=1;
        end
        if(blockID==10) begin
        data=prefetcher_data[0][2][63:32];
        pref_flag[10]=1;
        end
        if(blockID==11) begin
        data=prefetcher_data[0][2][31:0];
        pref_flag[11]=1;
        end
        /*LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j); */
        end 
        
        3: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][3][127:96];
        pref_flag[12]=1;
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][3][95:64];
        pref_flag[13]=1;
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][3][63:32];
        pref_flag[14]=1;
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][3][31:0];
        pref_flag[15]=1;
        end
       /* LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);*/
        end
        
        4: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][4][127:96];
        pref_flag[16]=1;
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][4][95:64];
        pref_flag[17]=1;
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][4][63:32];
        pref_flag[18]=1;
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][4][31:0];
        pref_flag[19]=1;
        end
        /*LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);*/
        end
        
        5: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][5][127:96];
        pref_flag[20]=1;
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][5][95:64];
        pref_flag[21]=1;
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][5][63:32];
        pref_flag[22]=1;
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][5][31:0];
        pref_flag[23]=1;
        end
       /* LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j);;*/
        end 
        
        6: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][6][127:96];
        pref_flag[24]=1;
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][6][95:64];
        pref_flag[25]=1;
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][6][63:32];
        pref_flag[26]=1;
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][6][31:0];
        pref_flag[27]=1;
        end
       /* LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j); */
        end     
 
        7: begin
        if(blockID==2'b00) begin
        data=prefetcher_data[0][7][127:96];
        pref_flag[28]=1;
        end
        if(blockID==2'b01) begin
        data=prefetcher_data[0][7][95:64];
        pref_flag[29]=1;
        end
        if(blockID==2'b10) begin
        data=prefetcher_data[0][7][63:32];
        pref_flag[30]=1;
        end
        if(blockID==2'b11) begin
        data=prefetcher_data[0][7][31:0];
        pref_flag[31]=1;
        end
        /*LRU_prefetch_count[0][j]=6'b111111;
        $display("LRU_prefetch_count[0][%d]=%d",j,LRU_prefetch_count[0][j]);
        LRUUpdate(j); */
        end          
        
    endcase
end    
else begin

end

end
endtask

task UpdatePrefecther;
input [31:0]address;
output [dataSize:0]data;
//reg [dataSize:0]data1,data2,data3,data4;
reg [31:0]address1;
integer k;
begin
$display("HI,entered update prefecter with address=%h", address);
Pref_in=Pref_in+1;
k=0;
address1=address;
address1[1:0]=2'b00;
findDataInMemory_pref1(address1,mem_data);
$display("address1=%h,data1=%h",address1,data1);
address1=address1+10'd1;
findDataInMemory_pref2(address1,mem_data);
$display("address2=%h,data2=%h",address1,data2);
address1=address1+10'd1;
findDataInMemory_pref3(address1,mem_data);
$display("address3=%h,data3=%h",address1,data3);
address1=address1+10'd1;
findDataInMemory_pref4(address1,mem_data);
$display("address4=%h,data4=%h",address1,data4);
address1=address1-10'd3;
$display("Data fetched successfuly");

//if(data1 != 32'hxxxxxxxx && data2 != 32'hxxxxxxxx && data3 != 32'hxxxxxxxx && data4 != 32'hxxxxxxxx)
if(data1 >= 32'h00000000 && data1 <= 32'hffffffff) 
begin


while(k<8 && ValidBit[k]) begin
k=k+1;   
$display("Hi, entered whileloop"); 
end
if(k<=7) begin
    $display("Copying data to prefecter");
    prefetcher_data[0][k][127:96]=data1;
    prefetcher_data[0][k][95:64]=data2;
    prefetcher_data[0][k][63:32]=data3;
    prefetcher_data[0][k][31:0]=data4;
    ValidBit[k]=1;
    prefetcher_tag[0][k]=address[31:2];
    LRU_prefetch_count[0][k]=6'b111111;
    LRUUpdate(k);
    $display("data prefetched");
end    
    
if(k==8)
    begin
    $display("Replacing prefetcher");
ReplacePrefetcher(address,data1,data2,data3,data4);
    end  
end
end

endtask

task LRUUpdate;
input integer k;
integer b;
begin
b=0;
$display("LRU update task entered");
while(b<k)begin
if(ValidBit[b]!=0) begin
LRU_prefetch_count[0][b]=LRU_prefetch_count[0][b]-1;
$display("LRU_prefetch_count[0][%d]=%d",b,LRU_prefetch_count[0][b]);
end
b=b+1;
end
b=b+1;
while(b<8) begin
if(prefetcher_tag[0][b]!=0) begin
LRU_prefetch_count[0][b]=LRU_prefetch_count[0][b]-1;
$display("LRU_prefetch_count[0][%d]=%d",b,LRU_prefetch_count[0][b]);
end
b=b+1;
end
end
endtask


task ReplacePrefetcher;
input [31:0]address;
input [dataSize:0]data1,data2,data3,data4;
integer a;
begin
$display("Prefetcher will be replaced");
a=0;
LeastusedData_prefetcher(block_no);
$display("Least used block:%d",block_no);
    case(block_no) 
    
    3'b000 : begin
                a=0;
                while(a<4) begin
                pref_cnt[0][a]=10'd0;
                if(pref_flag[a]==1)
                MoveDatatocache(a);
                a=a+1;
                end
                
             end
             
    3'b001 : begin
                //$display("case statement entered");
                a=4;
                while(a<8) begin
                pref_cnt[0][a]=10'd0;
                if(pref_flag[a]==1)
                MoveDatatocache(a);
                a=a+1;
                end
              end
              
    3'b010 : begin
                a=8;
                while(a<12) begin
                pref_cnt[0][a]=10'd0;
                if(pref_flag[a]==1)
                MoveDatatocache(a);
                a=a+1;
                end
             end
             
    3'b011 : begin
                a=12;
                while(a<16) begin
                pref_cnt[0][a]=10'd0;
                if(pref_flag[a]==1)
                MoveDatatocache(a);
                a=a+1;
                end
             end  
                        
    3'b100 : begin
                a=16;
                while(a<20) begin
                pref_cnt[0][a]=10'd0;
                if(pref_flag[a]==1)
                MoveDatatocache(a);
                a=a+1;
                end
             end
             
    3'b101 : begin
                a=20;
                while(a<24)begin
                pref_cnt[0][a]=10'd0;
                if(pref_flag[a]==1)
                MoveDatatocache(a);
                a=a+1;
                end
             end
             
    3'b110 : begin
             a=24;
             while(a<28) begin
             pref_cnt[0][a]=10'd0;
             if(pref_flag[a]==1)
             MoveDatatocache(a);
             a=a+1;
             end
             end
             
    3'b111 : begin
             a=28;
             while(a<32) begin
             pref_cnt[0][a]=10'd0;
             if(pref_flag[a]==1)
             MoveDatatocache(a);
             a=a+1;
             end 
             end             
              
    endcase
    
    prefetcher_data[0][block_no][127:96]=data1;
    prefetcher_data[0][block_no][95:64]=data2;
    prefetcher_data[0][block_no][63:32]=data3;
    prefetcher_data[0][block_no][31:0]=data4;
    ValidBit[block_no]=1;
    prefetcher_tag[0][block_no]=address[31:2];
    LRU_prefetch_count[0][block_no]=6'b111111;
    LRUUpdate(block_no);
    $display("prefetcher tag=%h",prefetcher_tag[0][block_no]);
end
endtask

task updateCache;
input [31:0] u_address;
input [31:0] u_data;
reg [5:0] index;
reg [25:0] tag;integer j;
begin
tag=u_address[31:6];
index=u_address[5:0];
j=index;
valid[j]=1;
tagArray[index]=tag;
dataArray[index]=u_data;
end

endtask



task MoveDatatocache;
input integer a;reg [31:0] c_data; reg [31:0] c_addr;
begin
Prefetcher_usage=Prefetcher_usage+1;
case(a)
    0: begin
    c_data=prefetcher_data[0][0][127:96];
    c_addr={prefetcher_tag[0][0],2'b00};
   // findCompFactor(data,CF);
    updateCache(c_addr,c_data);
    end
    1: begin
   c_data=prefetcher_data[0][0][95:64];
   c_addr={prefetcher_tag[0][0],2'b01};
   //findCompFactor(data,CF);
   updateCache(c_addr,c_data);
   end
    2: begin
   c_data=prefetcher_data[0][0][63:32];
   c_addr={prefetcher_tag[0][0],2'b10};
   //findCompFactor(data,CF);
   updateCache(c_addr,c_data);
   end
    3: begin
   c_data=prefetcher_data[0][0][31:0];
   c_addr={prefetcher_tag[0][0],2'b11};
  // findCompFactor(data,CF);
   updateCache(c_addr,c_data);
   end  
    4: begin
       c_data=prefetcher_data[0][1][127:96];
       c_addr={prefetcher_tag[0][1],2'b00};
      // findCompFactor(data,CF);
       updateCache(c_addr,c_data);
       end
    5: begin
      c_data=prefetcher_data[0][1][95:64];
      c_addr={prefetcher_tag[0][1],2'b01};
     // findCompFactor(data,CF);
      updateCache(c_addr,c_data);
      end
   6: begin
      c_data=prefetcher_data[0][1][63:32];
      c_addr={prefetcher_tag[0][1],2'b10};
     // findCompFactor(data,CF);
      updateCache(c_addr,c_data);
      end
   7: begin
      c_data=prefetcher_data[0][1][31:0];
      c_addr={prefetcher_tag[0][1],2'b11};
      //findCompFactor(data,CF);
      updateCache(c_addr,c_data);
      end 
    8: begin
          c_data=prefetcher_data[0][2][127:96];
          c_addr={prefetcher_tag[0][2],2'b00};
         // findCompFactor(data,CF);
          updateCache(c_addr,c_data);
          end
      9: begin
         c_data=prefetcher_data[0][2][95:64];
         c_addr={prefetcher_tag[0][2],2'b01};
        // findCompFactor(data,CF);
         updateCache(c_addr,c_data);
         end
      10: begin
         c_data=prefetcher_data[0][2][63:32];
         c_addr={prefetcher_tag[0][2],2'b10};
        // findCompFactor(data,CF);
         updateCache(c_addr,c_data);
         end
      11: begin
         c_data=prefetcher_data[0][2][31:0];
         c_addr={prefetcher_tag[0][2],2'b11};
        // findCompFactor(data,CF);
         updateCache(c_addr,c_data);
         end 
    12: begin
             c_data=prefetcher_data[0][3][127:96];
             c_addr={prefetcher_tag[0][3],2'b00};
         //    findCompFactor(data,CF);
             updateCache(c_addr,c_data);
             end
         13: begin
            c_data=prefetcher_data[0][3][95:64];
            c_addr={prefetcher_tag[0][3],2'b01};
          //  findCompFactor(data,CF);
            updateCache(c_addr,c_data);
            end
         14: begin
            c_data=prefetcher_data[0][3][63:32];
            c_addr={prefetcher_tag[0][3],2'b10};
         //   findCompFactor(data,CF);
            updateCache(c_addr,c_data);
            end
         15: begin
            c_data=prefetcher_data[0][3][31:0];
            c_addr={prefetcher_tag[0][3],2'b11};
          //  findCompFactor(data,CF);
            updateCache(c_addr,c_data);
            end 
    16: begin
                c_data=prefetcher_data[0][4][127:96];
                c_addr={prefetcher_tag[0][4],2'b00};
             //   findCompFactor(data,CF);
                updateCache(c_addr,c_data);
                end
            17: begin
               c_data=prefetcher_data[0][4][95:64];
               c_addr={prefetcher_tag[0][4],2'b01};
           //    findCompFactor(data,CF);
               updateCache(c_addr,c_data);
               end
            18: begin
               c_data=prefetcher_data[0][4][63:32];
               c_addr={prefetcher_tag[0][4],2'b10};
            //   findCompFactor(data,CF);
               updateCache(c_addr,c_data);
               end
            19: begin
               c_data=prefetcher_data[0][4][31:0];
               c_addr={prefetcher_tag[0][4],2'b11};
            //   findCompFactor(data,CF);
               updateCache(c_addr,c_data);
               end 
    20: begin
                   c_data=prefetcher_data[0][5][127:96];
                   c_addr={prefetcher_tag[0][5],2'b00};
              //     findCompFactor(data,CF);
                   updateCache(c_addr,c_data);
                   end
               21: begin
                  c_data=prefetcher_data[0][5][95:64];
                  c_addr={prefetcher_tag[0][5],2'b01};
                //  findCompFactor(data,CF);
                  updateCache(c_addr,c_data);
                  end
               22: begin
                  c_data=prefetcher_data[0][5][63:32];
                  c_addr={prefetcher_tag[0][5],2'b10};
              //    findCompFactor(data,CF);
                  updateCache(c_addr,c_data);
                  end
               23: begin
                  c_data=prefetcher_data[0][5][31:0];
                  c_addr={prefetcher_tag[0][5],2'b11};
                //  findCompFactor(data,CF);
                  updateCache(c_addr,c_data);
                  end 
    24: begin
                      c_data=prefetcher_data[0][6][127:96];
                      c_addr={prefetcher_tag[0][6],2'b00};
                 //     findCompFactor(data,CF);
                      updateCache(c_addr,c_data);
                      end
                  25: begin
                     c_data=prefetcher_data[0][6][95:64];
                     c_addr={prefetcher_tag[0][6],2'b01};
                 //    findCompFactor(data,CF);
                     updateCache(c_addr,c_data);
                     end
                  26: begin
                     c_data=prefetcher_data[0][6][63:32];
                     c_addr={prefetcher_tag[0][6],2'b10};
                //     findCompFactor(data,CF);
                     updateCache(c_addr,c_data);
                     end
                  27: begin
                     c_data=prefetcher_data[0][6][31:0];
                     c_addr={prefetcher_tag[0][6],2'b11};
               //      findCompFactor(data,CF);
                     updateCache(c_addr,c_data);
                     end 
    28 : begin
                         c_data=prefetcher_data[0][7][127:96];
                         c_addr={prefetcher_tag[0][7],2'b00};
                  //       findCompFactor(data,CF);
                         updateCache(c_addr,c_data);
                         end
                     29: begin
                        c_data=prefetcher_data[0][7][95:64];
                        c_addr={prefetcher_tag[0][7],2'b01};
                  //      findCompFactor(data,CF);
                        updateCache(c_addr,c_data);
                        end
                     30: begin
                        c_data=prefetcher_data[0][7][63:32];
                        c_addr={prefetcher_tag[0][7],2'b10};
                   //     findCompFactor(data,CF);
                        updateCache(c_addr,c_data);
                        end
                     31: begin
                        c_data=prefetcher_data[0][7][31:0];
                        c_addr={prefetcher_tag[0][7],2'b11};
                  //      findCompFactor(data,CF);
                        updateCache(c_addr,c_data);
                        end
                    
            
endcase
end
endtask

task LeastusedData_prefetcher;
output [2:0] block_no;
reg [5:0] X;
reg [4:0] c;
begin
c=0;
//$display("Least used data will be found");
X=LRU_prefetch_count[0][0];
//$display("X=%d",X);
while(c<8) begin
if(X>=LRU_prefetch_count[0][c]) begin
X=LRU_prefetch_count[0][c];
$display("X=%d",X);
$display("entered if statement");
end
c=c+1;
end
c=0;
while(X!=LRU_prefetch_count[0][c]) begin
c=c+1;
end
block_no[2:0]=c[2:0];
$display("block_no inside loop=%b",block_no);
$display("c=%b",c);
/*
end
if(LRU_prefetch_count[0][0]>=LRU_prefetch_count[0][1]) begin
X=LRU_prefetch_count[0][1];
block_no=3'b001;
$display("1");
end
else begin
X=LRU_prefetch_count[0][0];
block_no=3'b000;
$display("2");
end

if(X>=LRU_prefetch_count[0][2]) begin
X=LRU_prefetch_count[0][2];
block_no=3'b010;
$display("3");
end

if(X>=LRU_prefetch_count[0][3]) begin
X=LRU_prefetch_count[0][3];
block_no=3'b011;
$display("4");
end

if(X>=LRU_prefetch_count[0][4]) begin
X=LRU_prefetch_count[0][4];
block_no=3'b100;
$display("5");
end

if(X>=LRU_prefetch_count[0][5]) begin
X=LRU_prefetch_count[0][5];
block_no=3'b101;
$display("6");
end

if(X<=LRU_prefetch_count[0][6]) begin
X=LRU_prefetch_count[0][6];
block_no=3'b110;
$display("7");
end

if(X>=LRU_prefetch_count[0][7]) begin
X=LRU_prefetch_count[0][7];
block_no=3'b111;
$display("8");
end
*/
//block_no=c[2:0];
//$display("least used block=%b",block_no);
end
endtask


task findDataInMemory;
input [31:0] address;
output [dataSize:0]data;
integer offset,quotient,quotient1,newLineNum,x;
begin
	$display("Entered find data in memory with address: %h, mem_addr: %h", address, mem_addr);
	$display("mem valid : %b, mem ready : %b", mem_valid, mem_ready);
	mem_ready <= 0;
		if (mem_valid && !mem_ready) begin
			if (address < 1024) begin
				//$display("HIIIIII");
				mem_ready <= 1;
				mem_rdata = memory[mem_addr];
                                data_n = memory[address];
				$display("Data read");
				$display("mem_rdata:%h, Data_n:%h \n",mem_rdata, data_n);
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
end
end
end
endtask

task findDataInMemory_pref1;
input [31:0] address;
output [dataSize:0]data_n;
integer offset,quotient,quotient1,newLineNum,x;
begin
	$display("Entered find data in memory with address: %h, mem_addr: %h", address, mem_addr);
	$display("mem valid : %b, mem ready : %b", mem_valid, mem_ready);
	//mem_ready <= 0;
		//if (mem_valid && !mem_ready) begin
		//	$display("Hello");
		//	if (address < 1024) begin
		//		$display("HIIIIII");
				//mem_ready <= 1;
				//mem_rdata <= memory[mem_addr];
                                data1 = memory[address];
                                data_n = memory[address];
				$display("Data read");
				$display("mem_rdata:%h, Data1:%h \n",mem_rdata, data1);
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
//end
//end
end
endtask

task findDataInMemory_pref2;
input [31:0] address;
output [dataSize:0]data_n;
integer offset,quotient,quotient1,newLineNum,x;
begin
	$display("Entered find data in memory with address: %h, mem_addr: %h", address, mem_addr);
	$display("mem valid : %b, mem ready : %b", mem_valid, mem_ready);
	//mem_ready <= 0;
		//if (mem_valid && !mem_ready) begin
		//	$display("Hello");
		//	if (address < 1024) begin
		//		$display("HIIIIII");
				//mem_ready <= 1;
				//mem_rdata <= memory[mem_addr];
                                data2 = memory[address];
                                data_n = memory[address];
				$display("Data read");
				$display("mem_rdata:%h, Data2:%h \n",mem_rdata, data2);
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
//end
//end
end
endtask

task findDataInMemory_pref3;
input [31:0] address;
output [dataSize:0]data_n;
integer offset,quotient,quotient1,newLineNum,x;
begin
	$display("Entered find data in memory with address: %h, mem_addr: %h", address, mem_addr);
	$display("mem valid : %b, mem ready : %b", mem_valid, mem_ready);
	//mem_ready <= 0;
		//if (mem_valid && !mem_ready) begin
		//	$display("Hello");
		//	if (address < 1024) begin
		//		$display("HIIIIII");
				//mem_ready <= 1;
				//mem_rdata <= memory[mem_addr];
                                data3 = memory[address];
                                data_n = memory[address];
				$display("Data read");
				$display("mem_rdata:%h, Data3:%h \n",mem_rdata, data3);
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
//end
//end
end
endtask

task findDataInMemory_pref4;
input [31:0] address;
output [dataSize:0]data_n;
integer offset,quotient,quotient1,newLineNum,x;
begin
	$display("Entered find data in memory with address: %h, mem_addr: %h", address, mem_addr);
	$display("mem valid : %b, mem ready : %b", mem_valid, mem_ready);
	//mem_ready <= 0;
		//if (mem_valid && !mem_ready) begin
		//	$display("Hello");
		//	if (address < 1024) begin
		//		$display("HIIIIII");
				//mem_ready <= 1;
				//mem_rdata <= memory[mem_addr];
                                data4 = memory[address];
                                data_n = memory[address];
				$display("Data read");
				$display("mem_rdata:%h, Data4:%h \n",mem_rdata, data4);
				if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
				if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
				if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
				if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
//end
//end
end
endtask

endmodule



