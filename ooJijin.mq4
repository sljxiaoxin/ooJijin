//+------------------------------------------------------------------+
//|                              
//|  5分钟周期，zs 十点                                                    
//|                                              
//+------------------------------------------------------------------+
#property copyright "xiaoxin003"
#property link      "yangjx009@139.com"
#property version   "1.0"
#property strict

#include <Arrays\ArrayInt.mqh>
#include "mamgr.mqh"      //均线数值管理类
#include "lotsmgr.mqh"      //均线数值管理类
#include "dictionary.mqh" //keyvalue数据字典类
#include "citems.mqh"     //交易组item
#include "trademgr.mqh"   //交易工具类
#include "tpslmgr.mqh"   //


extern int       MagicNumber     = 20180213;
extern double    TPinMoney       = 0;          //Net TP (money)
extern double    tpPips          = 0;
extern double    slPips          = 0;
extern double    MaxGroupNum     = 1;
extern int       fastMa          = 50;
extern int       slowMa          = 89;
extern int       slowerMa        = 120;

int       NumberOfTries   = 10,
          Slippage        = 5;
datetime  CheckTime;
double    Pip;
CTradeMgr *objCTradeMgr;  //订单管理类
CDictionary *objDict = NULL;     //订单数据字典类
int tmp = 0;
double  Lots = 0.01;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   Print("begin");
   if(Digits==2 || Digits==4) Pip = Point;
   else if(Digits==3 || Digits==5) Pip = 10*Point;
   else if(Digits==6) Pip = 100*Point;
   if(objDict == NULL){
      objDict = new CDictionary();
      objCTradeMgr = new CTradeMgr(MagicNumber, Pip, NumberOfTries, Slippage);
      objCTpSlMgr = new CTpSlMgr(objCTradeMgr,objDict);
   }
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("deinit");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
     
     subPrintDetails();
     if(CheckTime==iTime(NULL,0,0)){
         return;
     } else {
         CheckTime = iTime(NULL,0,0);
         /*
            每次新柱的开始：
            1、获取计算均线所需数据，计算常用均线位置值。
         */
         Lots = LotsMgr::LotsMgr();  //动态lots
         CMaMgr::Init(fastMa,slowMa,slowerMa);
         objCTpSlMgr.Init(tpPips, slPips);
         objCTpSlMgr.DealTp();
         dealCrossOpen();
     }
 }

string  bigTradeType   = "none";      //3ema方向 buy sell none
string  smallTradeType = "none";
//只处理开单
void dealCrossOpen()
{
   
   if(objDict.Total()>=MaxGroupNum)return ;
   bigTradeType = bigTradeTypeCheck();
   smallTradeType = smallTradeTypeCheck();
   int t = 0;
   double oop = 0;
   if(smallTradeType == "crossUp"){
      t = objCTradeMgr.Buy(Lots, 0, 0, smallTradeType);
      if(t != 0){
         if(OrderSelect(t, SELECT_BY_TICKET)==true){
            oop = OrderOpenPrice();
         }
         objDict.AddObject(t, new CItems(t, type, TPinMoney, oop));
      }
   }else if(smallTradeType == "crossDown"){
      t = objCTradeMgr.Sell(Lots, 0, 0, type);
      if(t != 0){
         if(OrderSelect(t, SELECT_BY_TICKET)==true){
            oop = OrderOpenPrice();
         }
         objDict.AddObject(t, new CItems(t, type, TPinMoney, oop));
      }
   }
}

string bigTradeTypeCheck(){
   if(CMaMgr::s_ArrFastMa[0] > CMaMgr::s_ArrSlowMa[0] && 
                CMaMgr::s_ArrFastMa[0] > CMaMgr::s_ArrSlowerMa[0] && 
                CMaMgr::s_ArrSlowMa[0] > CMaMgr::s_ArrSlowerMa[0]){
       return "buy";         
   }
   if(CMaMgr::s_ArrFastMa[0] < CMaMgr::s_ArrSlowMa[0] && 
                CMaMgr::s_ArrFastMa[0] < CMaMgr::s_ArrSlowerMa[0] && 
                CMaMgr::s_ArrSlowMa[0] < CMaMgr::s_ArrSlowerMa[0]){
       return "sell";         
   }
   return "none";
}

string smallTradeTypeCheck(){
   double ma10_pre  = CMaMgr::GetMa10(3),
          ma10_next = CMaMgr::GetMa10(2),
          ma10Overying_pre  = CMaMgr::GetMa10Overlying(3),
          ma10Overying_next = CMaMgr::GetMa10Overlying(2);
   if(ma10_pre < ma10Overying_pre && ma10_next > ma10Overying_next){
      return "crossUp";
   }
   if(ma10_pre > ma10Overying_pre && ma10_next < ma10Overying_next){
      return "crossDown";
   }
   return "none";
}




void subPrintDetails()
{
   
   string sComment   = "";
   string sp         = "----------------------------------------\n";
   string NL         = "\n";

   sComment = sp;
   sComment = sComment + "Net = " + TotalNetProfit() + NL; 
   sComment = sComment + "GroupNum = " + objDict.Total() + NL; 
   sComment = sComment + sp;
   sComment = sComment + "Lots=" + DoubleToStr(Lots,2) + NL;
   Comment(sComment);
}

double TotalNetProfit()
{
     double op = 0;
     for(int cnt=0;cnt<OrdersTotal();cnt++)
      {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderType()<=OP_SELL &&
            OrderSymbol()==Symbol() &&
            OrderMagicNumber()==MagicNumber)
         {
            op = op + OrderProfit();
         }         
      }
      return op;
}

