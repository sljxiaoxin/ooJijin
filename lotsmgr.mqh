//+------------------------------------------------------------------+
//|                                                  LotsMgr.mqh |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015."
#property link      "http://www.mql5.com"

 class LotsMgr
 {
   private:
   
   public: 
      LotsMgr(){};
      ~LotsMgr(){};
      
      static double lots(){
         double equity = AccountEquity();
         if(equity <= 50){
            return 0.01;
         }else if(equity > 50 && equity <= 100){
            return 0.05;
         }else if(equity > 100 && equity <= 200){
            return 0.1;
         }else if(equity > 200 && equity <= 300){
            return 0.2;
         }else if(equity > 300 && equity <= 400){
            return 0.3;
         }else if(equity > 400 && equity <= 500){
            return 0.4;
         }else if(equity > 500 && equity <= 600){
            return 0.5;
         }else if(equity > 600 && equity <= 700){
            return 0.6;
         }else if(equity > 700 && equity <= 800){
            return 0.7;
         }else if(equity > 800 && equity <= 1000){
            return 0.8;
         }else if(equity > 1000 && equity <= 1500){
            return 1;
         }else if(equity > 1500 && equity <= 2000){
            return 1.5;
         }else if(equity > 2000 && equity <= 3000){
            return 2;
         }else if(equity > 3000 && equity <= 4000){
            return 3;
         }else if(equity > 4000 && equity <= 5000){
            return 4;
         }else if(equity > 5000 && equity <= 6000){
            return 5;
         }else if(equity > 6000 && equity <= 7000){
            return 6;
         }else if(equity > 7000 && equity <= 8000){
            return 7;
         }else if(equity > 8000 && equity <= 10000){
            return 8;
         }else if(equity > 10000 && equity <= 15000){
            return 10;
         }else if(equity > 15000 && equity <= 20000){
            return 15;
         }else if(equity > 20000 && equity <= 30000){
            return 18;
         }else if(equity > 30000 && equity <= 40000){
            return 20;
         }else if(equity > 40000 && equity <= 50000){
            return 22;
         }else if(equity > 50000 && equity <= 70000){
            return 25;
         }else if(equity > 70000 && equity <= 100000){
            return 30;
         }else if(equity > 100000 && equity <= 120000){
            return 50;
         }else if(equity > 120000 && equity <= 140000){
            return 60;
         }else if(equity > 140000 && equity <= 180000){
            return 70;
         }else if(equity > 180000 && equity <= 220000){
            return 90;
         }else if(equity > 220000 && equity <= 300000){
            return 100;
         }else if(equity > 300000 && equity <= 500000){
            return 120;
         }else {
            return 1;
         }
      }
      
 };