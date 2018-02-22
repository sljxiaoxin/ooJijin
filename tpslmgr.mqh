//+------------------------------------------------------------------+
//|                                                  CTpSlMgr.mqh |
//|                                 Copyright 2018, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018."
#property link      "http://www.mql5.com"

 class CTpSlMgr
 {
      private:
         CDictionary *m_dict;
         CTradeMgr *m_TradeMgr;
         double m_Pip;             //点值Point处理后
         double m_tpPips;
         
         double m_slPips;
         //移动止损相关
         bool m_isMoveSl;        //是否开启移动止损
         int m_Magic_Number;  
         int m_profitLock_pips;  //赚多少点平保
         int m_plPips;           //平保位于价格上多少点
         int m_TrailStop_pips;   //每隔多少点开始移动
         int m_TrailStep_pips;   //每次移动多少点
      public:
         
         CTpSlMgr(int Magic_Number,double Pip, CTradeMgr *TradeMgr, CDictionary *_dict){
            m_Magic_Number = Magic_Number;
            m_Pip = Pip;
            m_dict = _dict;
            m_TradeMgr = TradeMgr;
         };
         void Init(double tpPips, double slPips);
         void DealTp(string smallTradeType);    //zy或关闭单子
         void SetMoveSl(bool isMoveSl, int profitLock_pips, int plPips, int TrailStop_pips, int TrailStep_pips);
         void MoveSl();    //移动zs位
        // string smallTradeTypeCheck();  //交叉检测
         bool isItemAllClosed(CItems* item);
         double GetNetPips(int ticket);
         bool CloseItem(CItems* item);   //关闭item内所有订单
         bool isOrderClosed(int ticket);
 };
 void CTpSlMgr::Init(double tpPips, double slPips)
 {
      m_tpPips = tpPips;
      m_slPips = slPips;
 }
 
 void CTpSlMgr::DealTp(string smallTradeType)
 {
      if(m_dict.Total() <= 0)return;
      int ord_arr[20];
      int k = 0;
      for(int j=0;j<20;j++){
         ord_arr[j]=0;
      }
      //double smallTradeType = smallTradeTypeCheck();

           CItems* currItem = m_dict.GetFirstNode();
           for(int i = 1; (currItem != NULL && CheckPointer(currItem)!=POINTER_INVALID); i++)
           {
               double tickPips = GetNetPips(currItem.GetTicket()); //原始单净盈利点数 
               Print("m_tpPips:",m_tpPips,";tickPips:",tickPips);
               if(isItemAllClosed(currItem)){
                  //检查是否该组所有订单已经关闭，如果已经关闭，则需要释放
                  CloseItem(currItem);
                  ord_arr[k] = currItem.GetTicket();
                  k += 1;
               }else if(m_tpPips >0 && tickPips>= m_tpPips){
                  //达到zy点
                  CloseItem(currItem);
                  ord_arr[k] = currItem.GetTicket();
                  k += 1;
               }else if(smallTradeType!="none" && currItem.GetType() != smallTradeType){
                  //因cross关闭
                  CloseItem(currItem);
                  ord_arr[k] = currItem.GetTicket();
                  k += 1;
               }
               /*else if(currItem.GetType() == "crossUp" && ((Open[1]<Close[1] && High[1] - Close[1] >20*m_Pip) || (Open[1]>Close[1] && High[1] - Open[1] >30*m_Pip))){
                  //buy单上影线 和sell单下影线过长离场
                  CloseItem(currItem);
                  ord_arr[k] = currItem.GetTicket();
                  k += 1;
               }else if(currItem.GetType() == "crossDown" && ((Open[1]<Close[1] && Open[1] - Low[1] >20*m_Pip) || (Open[1]>Close[1] && Close[1] - Low[1] >30*m_Pip))){
                  //sell单下影线
                  CloseItem(currItem);
                  ord_arr[k] = currItem.GetTicket();
                  k += 1;
               }
               */
               if(m_dict.Total() >0){
                  currItem = m_dict.GetNextNode();
               }else{
                  currItem = NULL;
               }
           }
           for(int m=0;m<20;m++){
               if(ord_arr[m] > 0){
                  m_dict.DeleteObjectByKey(ord_arr[m]);  //删除止盈的item
                  Print("DeleteObjectByKey:",ord_arr[m]);
               }
           }
      
 }
 void CTpSlMgr::SetMoveSl(bool isMoveSl, int profitLock_pips, int plPips, int TrailStop_pips, int TrailStep_pips)
 {
   m_isMoveSl = isMoveSl;
   m_profitLock_pips = profitLock_pips; 
   m_plPips = plPips;
   m_TrailStop_pips = TrailStop_pips;
   m_TrailStep_pips = TrailStep_pips;
 }
 void CTpSlMgr::MoveSl(void)
 {
      if(m_dict.Total() <= 0)return;
      if(m_isMoveSl){
        double x,y,newSL,newSLy;
        double openPrice,myStopLoss;
        for (int i=0; i<OrdersTotal(); i++) {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {     
            if(OrderMagicNumber() == m_Magic_Number && OrderSymbol() == Symbol()){
               if(OrderType() == OP_BUY){
   		         openPrice = OrderOpenPrice();
   		         myStopLoss = OrderStopLoss();
                  if(myStopLoss<openPrice && Bid - openPrice > m_profitLock_pips*m_Pip){
                     //设置平保
                     newSL = openPrice+m_plPips*m_Pip;
                     OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
                  }
                  if(Bid - openPrice > m_TrailStop_pips*m_Pip){
                     //按比例移动止损
                     x = (Bid - openPrice)/(m_TrailStop_pips*m_Pip);
                     newSL = (openPrice-m_slPips*m_Pip)+x*m_TrailStep_pips*m_Pip;
                     if(myStopLoss + m_TrailStep_pips*m_Pip < newSL){
                        OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
                     }
                  }
               }
               if(OrderType() == OP_SELL){
   	            openPrice = OrderOpenPrice();
   	            myStopLoss = OrderStopLoss();
                  if(myStopLoss>openPrice && openPrice-Ask > m_profitLock_pips*m_Pip){
                     //设置平保
                     newSL = openPrice - m_plPips*m_Pip;
                     OrderModify(OrderTicket(),openPrice,newSL, OrderTakeProfit(), 0);
                  }
                  if(openPrice - Ask > m_TrailStop_pips*m_Pip){
                     y = (openPrice - Ask)/(m_TrailStop_pips*m_Pip);
                     newSLy = (openPrice+m_slPips*m_Pip)-y*m_TrailStep_pips*m_Pip;
                     if(myStopLoss-m_TrailStep_pips*m_Pip>newSLy){
                        OrderModify(OrderTicket(),openPrice,newSLy, OrderTakeProfit(), 0);
                     }
                  }
               }
            }
         }
        }
      }
 } 
 
 
 


 //如果有手动关闭了某组所有订单，需要释放组
 bool CTpSlMgr::isItemAllClosed(CItems* item)
 {
   if(!isOrderClosed(item.GetTicket())){
      return false;
   }
   if(item.Hedg != 0){
      if(!isOrderClosed(item.Hedg)){
         return false;
      }
   }
   for(int i=0;i<item.Marti.Total();i++){
      if(!isOrderClosed(item.Marti.At(i))){
         return false;
      }
   }
   return true;
   
 }
 
 double CTpSlMgr::GetNetPips(int ticket)
 {
    double pips = 0;
    if(OrderSelect(ticket, SELECT_BY_TICKET)==true){
        datetime dtc = OrderCloseTime();
        if(dtc >0){
            //订单已平仓，则返回0
            return pips;
        }
        int TradeType = OrderType();
        double openPrice = OrderOpenPrice();
        if(TradeType == OP_BUY){
            pips = (Ask - openPrice)/m_TradeMgr.GetPip();
        }
        if(TradeType == OP_SELL){
            pips = (openPrice - Bid)/m_TradeMgr.GetPip();
        }
    }
    return pips;
 }
 
  bool CTpSlMgr::CloseItem(CItems* item)
 {
      if(item.GetTicket() != 0){
         m_TradeMgr.Close(item.GetTicket());
      }
      if(item.Hedg != 0){
         m_TradeMgr.Close(item.Hedg);
      }
      for(int i=0;i<item.Marti.Total();i++){
         m_TradeMgr.Close(item.Marti.At(i));
      }
      return true;
 }
 
 bool CTpSlMgr::isOrderClosed(int ticket)
 {
    if(OrderSelect(ticket, SELECT_BY_TICKET)==true){
         datetime dtc = OrderCloseTime();
         if(dtc >0){
            return true;
         }else{
            return false;
         }
    }
    return false;
 }