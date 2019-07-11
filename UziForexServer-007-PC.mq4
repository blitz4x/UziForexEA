//+------------------------------------------------------------------+
//|                                                         UziForex |
//|                                               Powered by blitz4x |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Powered by blitz4x"
#property link      "https://blitz4x.com"
#property strict

//--- input parameters
input string   copyName  =  "BlitzTrade";
input color    colorBuy  =  clrLime;
input color    colorSell =  clrRed;
input color    colorNone =  clrYellow;

datetime nextOrdA = 0;
string   oldOrdA  = "End;";

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
   //----
   HideTestIndicators(true);
   
   string           www  = "https://blitz4x.com";
   if (ObjectFind  (www) < 0)
   {
      ObjectCreate (www, OBJ_LABEL,    0, 0, 0);
      ObjectSet    (www, OBJPROP_BACK,    true);
      ObjectSet    (www, OBJPROP_CORNER,     1);
      ObjectSet    (www, OBJPROP_ANGLE,     90);
      ObjectSet    (www, OBJPROP_XDISTANCE, 25);
      ObjectSet    (www, OBJPROP_YDISTANCE, 75);
      ObjectSetText(www, www, 10, "Tahoma", colorBuy);
   }
   Comment(WindowExpertName() + " Trading System");

   OnTick();
   
   //---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
   //---

}

//+------------------------------------------------------------------+
//| expert tick function                                            |
//+------------------------------------------------------------------+

void OnTick()
{
   int    pos;
   string OrdA = "";
   
   for (pos = OrdersTotal() - 1; pos >= 0; pos--)
   {
      if (!OrderSelect(pos, SELECT_BY_POS, MODE_TRADES))
      {
         Print(GetLastError());
         continue;
      }

      if (OrderType() == OP_BUY && OrderProfit() != 0)
      {
         /*
         OrdA = OrdA + "ord:"  + IntegerToString(OrderTicket())   + ";" + StringSubstr(OrderSymbol(), 0, 6) + ";" + IntegerToString(OP_BUY + 1) + ";" + "1.00;" + DoubleToStr(OrderOpenPrice(), 5) + ";" + DoubleToStr(OrderTakeProfit(), 5) + ";" + DoubleToStr(OrderStopLoss(), 5) + ";";
         */

         OrdA = OrdA + "ord:"  + IntegerToString(OrderTicket())   + ";" + StringSubstr(OrderSymbol(), 0, 6) + ";" + IntegerToString(OP_BUY + 1) + ";" + "1.00;" + DoubleToStr(OrderOpenPrice(), 5) + ";0.0;0.0;";

         continue;
      }

      if (OrderType() == OP_SELL && OrderProfit() != 0)
      {
         /*
         OrdA = OrdA + "ord:"  + IntegerToString(OrderTicket())   + ";" + StringSubstr(OrderSymbol(), 0, 6) + ";" + IntegerToString(OP_SELL + 1) + ";" + "1.00;" + DoubleToStr(OrderOpenPrice(), 5) + ";" + DoubleToStr(OrderTakeProfit(), 5) + ";" + DoubleToStr(OrderStopLoss(),  5) + ";";
         */

         OrdA = OrdA + "ord:"  + IntegerToString(OrderTicket())   + ";" + StringSubstr(OrderSymbol(), 0, 6) + ";" + IntegerToString(OP_SELL + 1) + ";" + "1.00;" + DoubleToStr(OrderOpenPrice(), 5) + ";0.0;0.0;";

         continue;
      }
   }

   for (pos = OrdersHistoryTotal() - 1; pos >= 0; pos--)
   {
      if (!OrderSelect(pos, SELECT_BY_POS, MODE_HISTORY))
      {
         Print(GetLastError());
         continue;
      }
      else if (((int)(TimeCurrent() - OrderCloseTime())) > 600)
      {
         continue;
      }
      else if (OrderType() < OP_BUY || OrderType() > OP_SELLSTOP)
      {
         continue;
      }

      OrdA = OrdA + "ord:" +
             IntegerToString(OrderTicket())    + ";" + StringSubstr(OrderSymbol(), 0, 6) + ";" + IntegerToString(-(OrderType() + 1)) + ";" +
             DoubleToStr(0.0,               1) + ";" + DoubleToStr(OrderOpenPrice(),  5) + ";" +
             DoubleToStr(OrderTakeProfit(), 5) + ";" + DoubleToStr(OrderStopLoss(),   5) + ";";
      continue;
   }

   OrdA = copyName + ";" + OrdA + "End;";
 
   if (OrdA != oldOrdA || TimeCurrent() > nextOrdA)
   {
      oldOrdA  = OrdA;
      nextOrdA = TimeCurrent() + 15;

      int file = FileOpen(copyName + ".dat", FILE_TXT | FILE_WRITE | FILE_COMMON);
      FileWriteString(file, OrdA);
      FileClose(file);
      
      if (ObjectFind ("Check text") < 0)
      {
         ObjectCreate("Check text", OBJ_LABEL,         0, 0, 0);
         ObjectSet   ("Check text", OBJPROP_COLOR,     colorNone);
         ObjectSet   ("Check text", OBJPROP_BACK,      false);
         ObjectSet   ("Check text", OBJPROP_CORNER,    2);
         ObjectSet   ("Check text", OBJPROP_XDISTANCE, 10);
         ObjectSet   ("Check text", OBJPROP_YDISTANCE, 50);
      }
      
      if (ObjectFind ("Check OrdA") < 0)
      {
         ObjectCreate("Check OrdA", OBJ_LABEL,         0, 0, 0);
         ObjectSet   ("Check OrdA", OBJPROP_COLOR,     colorNone);
         ObjectSet   ("Check OrdA", OBJPROP_BACK,      false);
         ObjectSet   ("Check OrdA", OBJPROP_CORNER,    2);
         ObjectSet   ("Check OrdA", OBJPROP_XDISTANCE, 10);
         ObjectSet   ("Check OrdA", OBJPROP_YDISTANCE, 30);
      }
   
      Comment(copyName + " " + TimeToStr(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS) + "\nOrdA=" + OrdA);
      ObjectSetText("Check text", "LAST UPDATE " + TimeToStr(TimeCurrent(), TIME_MINUTES | TIME_SECONDS), 14, "Tahoma Bold");
      ObjectSetText("Check OrdA", "OrdA: " + OrdA,                                                        14, "Tahoma Bold");
   }

   //----
}

//+------------------------------------------------------------------+
