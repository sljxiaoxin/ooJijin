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
         double m_tpPips;
         double m_slPips;
      public:
         
         CTpSlMgr(CTradeMgr *TradeMgr, CDictionary *_dict){
            m_dict = _dict;
            m_TradeMgr = TradeMgr;
         };
         void Init(double tpPips, double slPips);
         void DealTp();    //zy或关闭单子
         void MoveSl();    //移动zs位
         string smallTradeTypeCheck();  //交叉检测
         bool isItemAllClosed(CItems* item);
         double GetNetPips(int ticket);
         bool CloseItem(CItems* item);   //关闭item内所有订单
 };
 void CTpSlMgr::Init(double tpPips, double slPips)
 {
      m_tpPips = tpPips;
      m_slPips = slPips;
 }
 
 void CTpSlMgr::DealTp(void)
 {
      if(m_dict.Total() <= 0)return;
      int ord_arr[20];
      int k = 0;
      for(int j=0;j<20;j++){
         ord_arr[j]=0;
      }
      double smallTradeType = smallTradeTypeCheck();
      if(smallTradeType != "none"){
           CItems* currItem = m_dict.GetFirstNode();
           for(int i = 1; (currItem != NULL && CheckPointer(currItem)!=POINTER_INVALID); i++)
           {
               double tickPips = GetNetPips(currItem.GetTicket()); //原始单净盈利点数 
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
               }else if(currItem.GetType() != smallTradeType){
                  //因cross关闭
                  CloseItem(currItem);
                  ord_arr[k] = currItem.GetTicket();
                  k += 1;
               }
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
 }

 void CTpSlMgr::MoveSl(void)
 {
      if(m_dict.Total() <= 0)return;
 } 
 
 string CTpSlMgr::smallTradeTypeCheck(){
   double ma10_pre  = CMaMgr::GetMa10(2),
          ma10_next = CMaMgr::GetMa10(1),
          ma10Overying_pre  = CMaMgr::GetMa10Overlying(2),
          ma10Overying_next = CMaMgr::GetMa10Overlying(1);
   if(ma10_pre < ma10Overying_pre && ma10_next > ma10Overying_next){
      return "crossUp";
   }
   if(ma10_pre > ma10Overying_pre && ma10_next < ma10Overying_next){
      return "crossDown";
   }
   return "none";
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