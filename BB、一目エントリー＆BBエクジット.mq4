//マイライブラリー
#include <MyLib.mqh>

//マジックナンバー
#define MAGIC 20094040
#define COMMENT "BBMaster"

//外部パラメータ
extern double Lots = 0.1;
extern double Slippage = 3;

//エントリー関数
extern int BBPeriod = 20; //BB期間
extern int BBDev = 2; //標準偏差

int EntrySignal(int magic)
{
   //オープンポジションの計算
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   
   //BBの計算
   double upperNow = iBands(NULL, 0, BBPeriod, BBDev, 1, PRICE_OPEN, MODE_UPPER, 0);
   double lowerNow = iBands(NULL, 0, BBPeriod, BBDev, 1, PRICE_OPEN, MODE_LOWER,0);
   
   double upperPast = iBands(NULL, 0, BBPeriod, BBDev, 2, PRICE_OPEN, MODE_UPPER, 0);
   double lowerPast = iBands(NULL, 0, BBPeriod, BBDev, 2, PRICE_OPEN, MODE_LOWER,0);
   
   //一目均衡表の計算
   double senkouA = iIchimoku(NULL, 0, 9, 26, 52, MODE_SENKOUSPANA, -26);
   double senkouB = iIchimoku(NULL, 0, 9, 26, 52, MODE_SENKOUSPANB, -26);
   
   int ret = 0;
   //買いシグナル
   if(pos == 0 && Close[1] > upperNow && senkouA > senkouB)
      ret = 1;
   //売りシグナル
   if(pos == 0 && Close[1] < lowerNow && senkouA < senkouB) 
      ret = -1;
      
   return(ret);
}

int ExitSignal(int magic)
{
   //オープンポジションの計算
   double pos = MyCurrentOrders(MY_OPENPOS, magic);
   
   //BBの計算
   double upperNow = iBands(NULL, 0, BBPeriod, BBDev, 1, PRICE_OPEN, MODE_UPPER, 0);
   double lowerNow = iBands(NULL, 0, BBPeriod, BBDev, 1, PRICE_OPEN, MODE_LOWER,0);
   
   double upperPast = iBands(NULL, 0, BBPeriod, BBDev, 2, PRICE_OPEN, MODE_UPPER, 0);
   double lowerPast = iBands(NULL, 0, BBPeriod, BBDev, 2, PRICE_OPEN, MODE_LOWER,0);
   
   //決済シグナル
   int end = 0;
   if(pos >= 0 && upperNow < upperPast)
      end = 1;
   if(pos <= 0 && lowerNow > lowerPast)
      end = -1;
      
   return(end);

}

//注文送信関数
bool MyOrderSendSL(int type, double lots, double price, int slippage, int slpips, int tppips, string comment, int magic)
{
   int mult = 1;
   if(Digits == 3 || Digits == 5 ) mult = 10;
   slippage *= mult;
   if(type == OP_SELL || type == OP_SELLLIMIT || type == OP_SELLSTOP) mult *= -1;
   
   double sl = 0, tp = 0;
   if(slpips > 0) sl = price-slpips*Point*mult;
   if(tppips > 0) tp = price+tppips*Point*mult;
   
   return(MyOrderSend(type, lots, price, slippage, sl, tp, comment, magic));
}

//スタート関数
int start()
{
   //トレード可否
   if(IsTradeAllowed()==false)return(0);
   
   //バー始値制限処理
   static int BarsBefore = 0; //前回のティック更新時のバーの本数
   int BarsNow = Bars; //現在のバーの本数
   int BarsCheck = BarsNow-BarsBefore; //上の差
   

   //エントリーシグナル
   int sig_entry = EntrySignal(MAGIC);
   
   //買い注文
   if(BarsCheck == 1 && sig_entry > 0)
   {
      MyOrderSendSL(OP_BUY, Lots, Ask, Slippage, 0, 0, COMMENT, MAGIC);
   }
   //売り注文
   if(BarsCheck == 1 && sig_entry < 0)
   {
      MyOrderSendSL(OP_SELL, Lots, Bid, Slippage, 0, 0, COMMENT, MAGIC);
   }
   
   //決済シグナル
   int sig_exit = ExitSignal(MAGIC);
   
   //決済注文
   if(sig_exit > 0)
   {
      MyOrderClose(Slippage, MAGIC);
   }
   
   if(sig_exit < 0)
   {
      MyOrderClose(Slippage, MAGIC);
   }   
   
   //今回のティック更新時のバーの総数の記憶
   BarsBefore = BarsNow;
   
   return(0);
}