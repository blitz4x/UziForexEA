//+------------------------------------------------------------------+
//|                                                         UziForex |
//|                                               Powered by blitz4x |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Powered by blitz4x"
#property link      "https://blitz4x.com"
#property strict

//--- input parameters
input string   copyName       =  "BlitzTrade";
input double   baseLots       =  0.01;
input int      maxOpens       =  1000;
input double   takePip        =  1000.0;
input double   lossPip        =  1000.0;
input string   brokerPrefix   =  "";
input string   brokerSuffix   =  "";
input color    colorBuy       =  clrLime;
input color    colorSell      =  clrRed;
input color    colorNone      =  clrYellow;

int      timeframe  = 0,   oldOpens  = 0;
datetime nextPip    = 0,   startDate = 0;
datetime nextRes    = 0,   lastRes   = 0;
double   nowPip     = 0.0, oldPip    = 0.0;
double   oldProfit  = 0.0, oldLoss   = 0.0;
double   oldCommis  = 0.0, oldSwap   = 0.0;
string   lastMsg    = "";

double   lotSize     = 0.0;
double   openMoney   = 0.0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
   //---
   HideTestIndicators(true);

   string           www  = "https://blitz4x.com";
   if (ObjectFind  (www) < 0)
   {
      ObjectCreate (www, OBJ_LABEL,          0, 0, 0);
      ObjectSet    (www, OBJPROP_BACK,       true);
      ObjectSet    (www, OBJPROP_CORNER,     1);
      ObjectSet    (www, OBJPROP_ANGLE,      90);
      ObjectSet    (www, OBJPROP_XDISTANCE,  25);
      ObjectSet    (www, OBJPROP_YDISTANCE,  75);
      ObjectSet    (www, OBJPROP_SELECTABLE, false);
      ObjectSetText(www, www, 10, "Tahoma",  colorBuy);
   }
   Comment(WindowExpertName() + " Trading System");

   if (nextPip == 0)
   {
      Alert(WindowExpertName() + " starts @ " + TimeToStr(TimeCurrent()) + " BROKER TIME");
      print(WindowExpertName() + " starts @ " + TimeToStr(TimeLocal()), true);
   }

   nextRes = 0;
   lastRes = 0;
   nextPip = 0;
   
   lotSize = MathMax(baseLots, MarketInfo(NULL, MODE_MINLOT));
   lotSize = NormalizeDouble(lotSize, 2);
   
   openMoney = (lotSize*AccountLeverage()*250)/400;

   OnTick();
   
   //---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
   //---

}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
   //---
   checkPoint();
         
   int    digs;
   int    i, pos, totOpens  = 0;
   double totProfit = 0.0, totLoss  = 0.0;
   double totCommis = 0.0, totSwap  = 0.0;
   double pips;

   nowPip = 0.0;

   for (pos = 0; pos < OrdersTotal(); pos++)
   {
      if (!OrderSelect(pos, SELECT_BY_POS, MODE_TRADES))
      {
         continue;
      }
      
      if (OrderType() < OP_BUY || OrderType() > OP_SELLSTOP)
      {
         continue;
      }

      if (StringFind(OrderComment(), copyName) >= 0)
      {
         totOpens += 1;

         if (OrderProfit() < 0) totLoss   += OrderProfit();
         else                   totProfit += OrderProfit();

         totCommis += OrderCommission();
         totSwap   += OrderSwap();

         if (OrderType() == OP_BUY || OrderType() == OP_SELL)
         {
            pips    = MarketInfo(OrderSymbol(), MODE_POINT)*MathPow(10, MathMod(MarketInfo(OrderSymbol(), MODE_DIGITS), 2));
            nowPip += (OrderClosePrice() - OrderOpenPrice ())/pips;
         }
      }
   }

   string          sTime = "BAR Time";
   if (ObjectFind (sTime) < 0)
   {
      ObjectCreate(sTime, OBJ_LABEL,         0, 0, 0);
      ObjectSet   (sTime, OBJPROP_BACK,      false);
      ObjectSet   (sTime, OBJPROP_CORNER,    1);
   }
   ObjectSet      (sTime, OBJPROP_XDISTANCE, 5);
   ObjectSet      (sTime, OBJPROP_YDISTANCE, 20);
   ObjectSetText  (sTime, Symbol() + " " + TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS), 9, "Tahoma", colorBuy);

   if (TimeCurrent() > nextPip || totOpens != oldOpens)
   {
      oldOpens  = totOpens;
      nextPip   = TimeCurrent() + 60;
      startDate = TimeCurrent();

      int      o = 0; string oOrd[];
      double   oPip[], pipIn = 0.0, pipOut = 0.0;
      datetime nightDate = StringToTime(TimeToStr(TimeCurrent(), TIME_DATE));

      oldPip    = 0.0;
      oldProfit = 0.0;
      oldLoss   = 0.0;
      oldCommis = 0.0;
      oldSwap   = 0.0;
      
      ArrayResize(oOrd,  0);
      ArrayResize(oPip,  0);

      for (pos = (OrdersHistoryTotal()-1); pos >= 0; pos--)
      {
         if (!OrderSelect(pos, SELECT_BY_POS, MODE_HISTORY))   continue;
         if (OrderType() != OP_BUY && OrderType() != OP_SELL)  continue;

         startDate = MathMin(startDate, OrderOpenTime());

         o = ArraySize(oOrd);
         ArrayResize(oOrd, o + 1);
         ArrayResize(oPip, o + 1);

         if (OrderProfit() < 0)
         {
            oldLoss += OrderProfit();
         }
         else
         {
            oldProfit += OrderProfit();
         }

         oldCommis += OrderCommission();
         oldSwap   += OrderSwap();

         pips = MarketInfo(OrderSymbol(), MODE_POINT)*MathPow(10, MathMod(MarketInfo(OrderSymbol(), MODE_DIGITS), 2));

         if (OrderType() == OP_BUY)
         {
            oPip[o] = (OrderClosePrice() - OrderOpenPrice ())/pips;
            oOrd[o] = TimeToString(OrderOpenTime(), TIME_DATE) + " " + OrderSymbol() + " BUY ";

            if (OrderOpenTime() >= nightDate)
            {
               oldPip += oPip[o];
            }
         }

         if (OrderType() == OP_SELL)
         {
            oPip[o] = (OrderOpenPrice () - OrderClosePrice())/pips;
            oOrd[o] = TimeToString(OrderOpenTime(), TIME_DATE) + " " + OrderSymbol() + " SELL ";

            if (OrderOpenTime() >= nightDate)
            {
               oldPip += oPip[o];
            }
         }
      
         if      (oPip[o] > 0) pipIn  += oPip[o];
         else if (oPip[o] < 0) pipOut -= oPip[o];
      }

      if (ObjectFind ("Pips") >= 0)
      {
         ObjectDelete("Pips");
      }
         
      ObjectCreate("Pips", OBJ_LABEL,      0, 0, 0);
      ObjectSet   ("Pips", OBJPROP_BACK,   false);
      ObjectSet   ("Pips", OBJPROP_CORNER, 1);
      ObjectSet   ("Pips", OBJPROP_XDISTANCE, 5);
      ObjectSet   ("Pips", OBJPROP_YDISTANCE, 35);

      if (ObjectFind ("Start") >= 0)
      {
         ObjectDelete("Start");
      }

      ObjectCreate("Start", OBJ_LABEL,         0, 0, 0);
      ObjectSet   ("Start", OBJPROP_BACK,      false);
      ObjectSet   ("Start", OBJPROP_CORNER,    1);
      ObjectSet   ("Start", OBJPROP_XDISTANCE, 5);
      ObjectSet   ("Start", OBJPROP_YDISTANCE, 50);
      
      double   totPips = pipIn - pipOut;
      if      (totPips > 0)
      {
         ObjectSetText("Pips",  "Pips "  + DoubleToStr(pipIn,   1) +  " - "  +
                                           DoubleToStr(pipOut,  1) +  " = +" +
                                           DoubleToStr(totPips, 1),                        10, "Tahoma", colorBuy);
         ObjectSetText("Start", "Since " + TimeToStr(startDate, TIME_DATE | TIME_MINUTES), 10, "Tahoma", colorBuy);
      }
      else if (totPips < 0)
      {
         ObjectSetText("Pips",  "Pips "  + DoubleToStr(pipIn,   1) +  " - "  +
                                           DoubleToStr(pipOut,  1) +  " = " +
                                           DoubleToStr(totPips, 1),                        10, "Tahoma", colorSell);
         ObjectSetText("Start", "Since " + TimeToStr(startDate, TIME_DATE | TIME_MINUTES), 10, "Tahoma", colorSell);
      }
      else
      {
         ObjectSetText("Pips",  "Pips "  + DoubleToStr(pipIn,   1) +  " - " +
                                           DoubleToStr(pipOut,  1) +  " = " +
                                           DoubleToStr(totPips, 1),                        10, "Tahoma", colorNone);
         ObjectSetText("Start", "Since " + TimeToStr(startDate, TIME_DATE | TIME_MINUTES), 10, "Tahoma", colorNone);
      }

      string oName;
      for (i = 0; i < 100; i++)
      {
         oName = "oPip " + IntegerToString(i);
         if (ObjectFind(oName) >= 0) ObjectDelete(oName);
         else                        break;
      }

      for (i = 0; i < ArraySize(oOrd); i++)
      {
         oName = "oPip " + IntegerToString(i);
         ObjectCreate(oName, OBJ_LABEL,         0, 0, 0);
         ObjectSet   (oName, OBJPROP_BACK,      true);
         ObjectSet   (oName, OBJPROP_CORNER,    1);
         ObjectSet   (oName, OBJPROP_XDISTANCE, 25);
         ObjectSet   (oName, OBJPROP_YDISTANCE, 70 + i*12);

         if      (oPip[i] > 0) ObjectSetText(oName, oOrd[i] + DoubleToStr(oPip[i], 1), 8, "Tahoma", colorBuy);
         else if (oPip[i] < 0) ObjectSetText(oName, oOrd[i] + DoubleToStr(oPip[i], 1), 8, "Tahoma", colorSell);
         else                  ObjectSetText(oName, oOrd[i] + DoubleToStr(oPip[i], 1), 8, "Tahoma", colorNone);
      }
   }

   double nowLoss = totLoss   + totCommis;
   double dayLoss = totLoss   + totCommis + oldLoss + oldCommis;

   double nowTake = totProfit + (totSwap > 0 ? totSwap : 0);
   double dayTake = totProfit + (totSwap > 0 ? totSwap : 0) + oldProfit + (oldSwap > 0 ? oldSwap : 0);

   double nowTots = nowLoss   + nowTake + (totSwap < 0 ? totSwap : 0);
   double dayTots = dayLoss   + dayTake + (totSwap < 0 ? totSwap : 0)   + (oldSwap < 0 ? oldSwap : 0);

   double day100    =  dayTots/openMoney*100;
   string alarmText = "GAIN "    + DoubleToStr(dayTake, 2) +
                      " LOSS "   + DoubleToStr(dayLoss, 2) +
                      " = TOT "  + DoubleToStr(dayTots, 2) +
                      " = RATE " + DoubleToStr(day100,  2) + " %";

   if (ObjectFind ("Account Alarm") < 0)
   {
      ObjectCreate("Account Alarm", OBJ_LABEL, 0, 0, 0);
      ObjectSet   ("Account Alarm", OBJPROP_BACK, false);
      ObjectSet   ("Account Alarm", OBJPROP_CORNER, 2);
   }
   ObjectSet      ("Account Alarm", OBJPROP_XDISTANCE, 10);
   ObjectSet      ("Account Alarm", OBJPROP_YDISTANCE, 30);

   ObjectSetText("Account Alarm", alarmText, 10, "Tahoma");
   if      (dayTots > 0) ObjectSet("Account Alarm", OBJPROP_COLOR, colorBuy);
   else if (dayTots < 0) ObjectSet("Account Alarm", OBJPROP_COLOR, colorSell);
   else                  ObjectSet("Account Alarm", OBJPROP_COLOR, colorNone);
   
   string localText = "Open TAKE "  + DoubleToStr(nowTake,   2) +
                      " Open LOSS " + DoubleToStr(nowLoss,   2) +
                      " = "         + DoubleToStr(nowTots,   2);

   if (ObjectFind ("Accouunt Local") < 0)
   {
      ObjectCreate("Accouunt Local", OBJ_LABEL, 0, 0, 0);
      ObjectSet   ("Accouunt Local", OBJPROP_BACK, false);
      ObjectSet   ("Accouunt Local", OBJPROP_CORNER, 2);
   }
   ObjectSet      ("Accouunt Local", OBJPROP_XDISTANCE, 10);
   ObjectSet      ("Accouunt Local", OBJPROP_YDISTANCE, 50);

   ObjectSetText("Accouunt Local", localText, 10, "Tahoma");
   if      (nowTots > 0) ObjectSet("Accouunt Local", OBJPROP_COLOR, colorBuy);
   else if (nowTots < 0) ObjectSet("Accouunt Local", OBJPROP_COLOR, colorSell);
   else                  ObjectSet("Accouunt Local", OBJPROP_COLOR, colorNone);

   double checkPip = nowPip + oldPip;

   if (checkPip < (-1*MathAbs(lossPip)) || checkPip > takePip)
   {
      if (totOpens > 0)
      {
         closeAll(true);
         Alert("Trading bloccato per TAKE/LOSS");
      }

      return;
   }

   int file = FileOpen(copyName + ".dat", FILE_TXT | FILE_READ | FILE_COMMON);
   string res = FileReadString(file);
   FileClose(file);
   
   string check = "----------\nPowered by UziForex\n" + WindowExpertName();
   
   if (res == "")
   {
      check = "\n----------\nThe SERVER is not responding...\nTry again in 15 seconds";
      nextRes = TimeCurrent() + 15;
   }
   else while (StringLen(res) > 0)
   {
      if (StringSubstr(res, 0, 2) == "NO")
      {
         check = check + "\n----------\nThe SERVER refuse your connection\nTry again in 1 minute";
         nextRes = TimeCurrent() + 60;
         break;
      }
      else if (StringSubstr(res, 0, StringFind(res, ";")) == copyName)
      {
         check = check + "\n----------\nConnection OK!";
         res   = StringSubstr(res, StringFind(res, ";") + 1);
      }
      else if (StringSubstr(res, 0, StringFind(res, ";")) == "CheckOK")
      {
         check = check + "\nSERVER check OK!\nNO problem detected";
         res   = StringSubstr(res, StringFind(res, ";") + 1);
      }
      else if (StringSubstr(res, 0, 4) == "ord:")
      {
         lastRes = TimeCurrent();
      
         // ord:38832724;EURUSD;2;5600.0;0.88834;0.00000;0.00000;
         res = StringSubstr(res, StringFind(res, ":") + 1);

         int nMagic = StrToInteger(StringSubstr(res, 0, StringFind(res, ";")));
         res = StringSubstr(res, StringFind(res, ";") + 1);

         string symbol = brokerPrefix + StringSubstr(res, 0, StringFind(res, ";")) + brokerSuffix;
         res = StringSubstr(res, StringFind(res, ";") + 1);
         check = check + "\n" + symbol;

         int type = StrToInteger(StringSubstr(res, 0, StringFind(res, ";")));
         res = StringSubstr(res, StringFind(res, ";") + 1);

         if (type >= 0)
         {
            switch (+type - 1)
            {
               case OP_BUY:       check = check + " BUY OPEN";          break;
               case OP_SELL:      check = check + " SELL OPEN";         break;
               case OP_BUYSTOP:   check = check + " BUY STOP PLACED";   break;
               case OP_SELLSTOP:  check = check + " SELL STOP PLACED";  break;
               case OP_BUYLIMIT:  check = check + " BUY LIMIT PLACED";  break;
               case OP_SELLLIMIT: check = check + " SELL LIMIT PLACED"; break;
            }
         }
         else
         {
            switch (-type - 1)
            {
               case OP_BUY:       check = check + " BUY CLOSED";         break;
               case OP_SELL:      check = check + " SELL CLOSED";        break;
               case OP_BUYSTOP:   check = check + " BUY STOP DELETED";   break;
               case OP_SELLSTOP:  check = check + " SELL STOP DELETED";  break;
               case OP_BUYLIMIT:  check = check + " BUY LIMIT DELETED";  break;
               case OP_SELLLIMIT: check = check + " SELL LIMIT DELETED"; break;
            }
         }

         double lots = StrToDouble(StringSubstr(res, 0, StringFind(res, ";")));
         res = StringSubstr(res, StringFind(res, ";") + 1);

         double open = StrToDouble(StringSubstr(res, 0, StringFind(res, ";")));
         res = StringSubstr(res, StringFind(res, ";") + 1);

         double take = StrToDouble(StringSubstr(res, 0, StringFind(res, ";")));
         res = StringSubstr(res, StringFind(res, ";") + 1);

         double stop = StrToDouble(StringSubstr(res, 0, StringFind(res, ";")));
         res  = StringSubstr(res, StringFind(res, ";") + 1);

         double ticket = 0;

         for (pos = 0; pos < OrdersTotal(); pos++)
         {
            if (OrderSelect(pos, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == nMagic)
            {
               ticket = OrderTicket();

               if (type < 0)
               {
                  close(OrderTicket());
               }
               else
               {
                  digs = (int)MarketInfo(symbol, MODE_DIGITS);
                  pips = MarketInfo(OrderSymbol(), MODE_POINT)*MathPow(10, MathMod(digs, 2));

                  if (OrderType() == OP_BUY || OrderType() == OP_SELL) open = OrderOpenPrice();
                  else                                                 open = NormalizeDouble(open, digs);
                                        
                  take = NormalizeDouble(take, digs);
                  stop = NormalizeDouble(stop, digs);

                  if ((MathAbs(OrderOpenPrice() - open) > 1*pips) ||
                      (MathAbs(OrderStopLoss () - stop) > 1*pips) || (MathAbs(OrderTakeProfit() - take) > 1*pips))
                     if (!OrderModify(OrderTicket(), open, stop, take, 0))
                        print(OrderSymbol() + " buy take/stop error " + IntegerToString(GetLastError()));
               }

               break;
            }
         }
         
         if (ticket == 0) for (pos = (OrdersHistoryTotal()-1); pos >= 0; pos--)
         {
            if (OrderSelect(pos, SELECT_BY_POS, MODE_HISTORY) && OrderMagicNumber() == nMagic)
            {
               ticket = OrderTicket();
               break;
            }
         }

         if (totOpens < maxOpens)
         {
            double xLots = lotSize*lots;
   
            if      (ticket   > 0)                         continue;
            else if ((type - 1) == OP_BUY)       buy      (symbol, xLots, open, nMagic, copyName);
            else if ((type - 1) == OP_SELL)      sell     (symbol, xLots, open, nMagic, copyName);
            else if ((type - 1) == OP_BUYSTOP)   buyStop  (symbol, xLots, open, nMagic, copyName);
            else if ((type - 1) == OP_SELLSTOP)  sellStop (symbol, xLots, open, nMagic, copyName);
            else if ((type - 1) == OP_BUYLIMIT)  buyLimit (symbol, xLots, open, nMagic, copyName);
            else if ((type - 1) == OP_SELLLIMIT) sellLimit(symbol, xLots, open, nMagic, copyName);
   
            totOpens += 1;
         }
      }
      else if (StringSubstr(res, 0, 4) == "MSG:")
      {
         string msg = StringSubstr(res, 4, StringFind(res, ";") - 4);
         res = StringSubstr(res, StringFind(res, ";") + 1);
         check = check + "\n----------\n" + msg;

         if (msg != lastMsg)
         {
            Alert(msg);
            print(msg);
            lastMsg = msg;
         }
      }
      else if (StringSubstr(res, 0, 6) == "Pause:")
      {
         int pause = StrToInteger(StringSubstr(res, 6, StringFind(res, ";") - 6));
         res = StringSubstr(res, StringFind(res, ";") + 1);
         check = check + "\n----------\nServer connected but in pause for " + IntegerToString(pause) + " seconds";
         nextRes = TimeCurrent() + pause;
      }
      else if (StringSubstr(res, 0, 4) == "End;")
      {
         check = check + "\n----------\nEnd";
         break;
      }
      else if (StringLen(res) > 0)
      {
         check = check + "\n----------\nCONNECTION ERROR...\nres:" + res;
         nextRes = TimeCurrent() + 15;
         break;
      }
   }
   
   Comment(check);
}

int print(string text, bool flashing = false)
{
   if (ObjectFind ("Check text") < 0)
   {
      ObjectCreate("Check text", OBJ_LABEL,         0, 0, 0);
      ObjectSet   ("Check text", OBJPROP_COLOR,     White);
      ObjectSet   ("Check text", OBJPROP_BACK,      false);
      ObjectSet   ("Check text", OBJPROP_CORNER,    2);
   }
   ObjectSet      ("Check text", OBJPROP_XDISTANCE, 10);
   ObjectSet      ("Check text", OBJPROP_YDISTANCE, 70);
   ObjectSetText  ("Check text", TimeToStr(TimeLocal(), TIME_SECONDS) + " " + text, 10, "Tahoma", colorBuy);

   if      (flashing && ObjectGet("Check text", OBJPROP_COLOR) == colorBuy)  ObjectSet("Check text", OBJPROP_COLOR, colorSell);
   else if (flashing && ObjectGet("Check text", OBJPROP_COLOR) == colorSell) ObjectSet("Check text", OBJPROP_COLOR, colorBuy);
   else                                                                      ObjectSet("Check text", OBJPROP_COLOR, colorNone);

   return(0);
}

int checkPoint()
{
   RefreshRates();
          
   double pip    = Point*MathPow(10, Digits%2);
   double pipVal = MarketInfo(Symbol(), MODE_TICKVALUE)*MathPow(10, Digits%2)*lotSize;
   double spread = NormalizeDouble((Ask - Bid)/pip, Digits);

   if (ObjectFind ("Spread") < 0)
   {
      ObjectCreate("Spread", OBJ_LABEL, 0, 0, 0);
      ObjectSet   ("Spread", OBJPROP_BACK, false);
      ObjectSet   ("Spread", OBJPROP_CORNER, 2);
      ObjectSet   ("Spread", OBJPROP_XDISTANCE, 10);
      ObjectSet   ("Spread", OBJPROP_YDISTANCE, 10);
   }
   ObjectSet      ("Spread", OBJPROP_XDISTANCE, 10);
   ObjectSet      ("Spread", OBJPROP_YDISTANCE, 10);
   ObjectSetText  ("Spread", Symbol()   +
                           " 1 pip x "  + DoubleToStr(lotSize, 2) + " lots = " + DoubleToStr(pipVal, 2) +
                           " leverage " + IntegerToString(AccountLeverage()) +
                           " spread "   + DoubleToStr(spread,  1) + " pips", 10, "Tahoma", colorBuy);
                           
   return(0);
}

int buy(string symbol, double xlot, double openBuy, int magic, string ordA)
{
   for (int i = 1; IsTradeContextBusy(); i++)
   {
      print("TRADE CONTEXT BUSY... ATTEMPT " + IntegerToString(i), true);
      Sleep(1000);
   }

   int ticket = 0;
   if (IsTradeAllowed())
   {
      RefreshRates();
      double ask =      MarketInfo(symbol, MODE_ASK);
      int    dig = (int)MarketInfo(symbol, MODE_DIGITS);
      double pip =      MarketInfo(OrderSymbol(), MODE_POINT)*MathPow(10, MathMod(dig, 2));
      ticket     =      OrderSend(symbol, OP_BUY, xlot, NormalizeDouble(ask, dig), 0, 0, 0, ordA + " BUY", magic, 0);
   }
   
   if (ticket > 0)
   {
      print("BUY " + symbol + " OK!");
      while (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) Sleep(100);
      return(ticket);
   }
   else
   {
      print("BUY " + symbol + " error #" + IntegerToString(GetLastError()));
      return(-1);
   }
}

int buyStop(string symbol, double xlot, double openBuy, int magic, string ordA)
{
   for (int i = 1; IsTradeContextBusy(); i++)
   {
      print("TRADE CONTEXT BUSY... ATTEMPT " + IntegerToString(i), true);
      Sleep(1000);
   }

   int ticket = 0;
   if (IsTradeAllowed())
   {
      RefreshRates();
      int dig = (int)MarketInfo(symbol, MODE_DIGITS);
      ticket  =      OrderSend (symbol, OP_BUYSTOP, xlot, NormalizeDouble(openBuy, dig), 0, 0, 0, ordA + " BUYSTOP", magic, 0);
   }

   if (ticket > 0)
   {
      print("BUYSTOP " + symbol + " OK!");
      while (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) Sleep(100);
      return(ticket);
   }
   else
   {
      print("BUYSTOP " + symbol + " error #" + IntegerToString(GetLastError()));
      return(-1);
   }
}

int buyLimit(string symbol, double xlot, double openBuy, int magic, string ordA)
{
   for (int i = 1; IsTradeContextBusy(); i++)
   {
      print("TRADE CONTEXT BUSY... ATTEMPT " + IntegerToString(i), true);
      Sleep(1000);
   }

   int ticket = 0;
   if (IsTradeAllowed())
   {
      RefreshRates();
      int dig = (int)MarketInfo(symbol, MODE_DIGITS);
      ticket  =      OrderSend (symbol, OP_BUYLIMIT, xlot, NormalizeDouble(openBuy, dig), 0, 0, 0, ordA + " BUYLIMIT", magic, 0);
   }

   if (ticket > 0)
   {
      print("BUY " + symbol + " OK!");
      while (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) Sleep(100);
      return(ticket);
   }
   else
   {
      print("BUY " + symbol + " error #" + IntegerToString(GetLastError()));
      return(-1);
   }
}

int sell(string symbol, double xlot, double openSell, int magic, string ordA)
{
   for (int i = 1; IsTradeContextBusy(); i++)
   {
      print("TRADE CONTEXT BUSY... ATTEMPT " + IntegerToString(i), true);
      Sleep(1000);
   }

   int ticket = 0;
   if (IsTradeAllowed())
   {
      RefreshRates();
      double bid =      MarketInfo(symbol, MODE_BID);
      int    dig = (int)MarketInfo(symbol, MODE_DIGITS);
      double pip =      MarketInfo(OrderSymbol(), MODE_POINT)*MathPow(10, MathMod(dig, 2));
      ticket     =      OrderSend(symbol, OP_SELL, xlot, NormalizeDouble(bid, dig), 0, 0, 0, ordA + " SELL", magic, 0);
   }

   if (ticket > 0)
   {
      print("SELL " + symbol + " OK!");
      while (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) Sleep(100);
      return(ticket);
   }
   else
   {
      print("SELL " + symbol + " error #" + IntegerToString(GetLastError()));
      return(-1);
   }
}

int sellStop(string symbol, double xlot, double openSell, int magic, string ordA)
{
   for (int i = 1; IsTradeContextBusy(); i++)
   {
      print("TRADE CONTEXT BUSY... ATTEMPT " + IntegerToString(i), true);
      Sleep(1000);
   }

   int ticket = 0;
   if (IsTradeAllowed())
   {
      RefreshRates();
      int dig = (int)MarketInfo(symbol, MODE_DIGITS);
      ticket  =      OrderSend (symbol, OP_SELLSTOP, xlot, NormalizeDouble(openSell, dig), 0, 0, 0, ordA + " SELLSTOP", magic, 0);
   }

   if (ticket > 0)
   {
      print("SELLSTOP " + symbol + " OK!");
      while (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) Sleep(100);
      return(ticket);
   }
   else
   {
      print("SELLSTOP " + symbol + " error #" + IntegerToString(GetLastError()));
      return(-1);
   }
}

int sellLimit(string symbol, double xlot, double openSell, int magic, string ordA)
{
   for (int i = 1; IsTradeContextBusy(); i++)
   {
      print("TRADE CONTEXT BUSY... ATTEMPT " + IntegerToString(i), true);
      Sleep(1000);
   }

   int ticket = 0;
   if (IsTradeAllowed())
   {
      RefreshRates();
      int dig = (int)MarketInfo(symbol, MODE_DIGITS);
      ticket  =      OrderSend (symbol, OP_SELLLIMIT, xlot, NormalizeDouble(openSell, dig), 0, 0, 0, ordA + " SELLLIMIT", magic, 0);
   }

   if (ticket > 0)
   {
      print("SELLLIMIT " + symbol + " OK!");
      while (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) Sleep(100);
      return(ticket);
   }
   else
   {
      print("SELLLIMIT " + symbol + " error #" + IntegerToString(GetLastError()));
      return(-1);
   }
}

int close(int ticket)
{
   if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES) == false)
   {
      print("Error#" + IntegerToString(GetLastError()) + " selecting " + IntegerToString(ticket));
      return(-1);
   }

   RefreshRates();
	double ask =      MarketInfo(OrderSymbol(), MODE_ASK);
	double bid =      MarketInfo(OrderSymbol(), MODE_BID);
	int    dig = (int)MarketInfo(OrderSymbol(), MODE_DIGITS);

   if     (OrderType() == OP_BUY)
   {
      if (!OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(bid, dig), 0))
      {
         print("Error#" + IntegerToString(GetLastError()) + " closing " + OrderSymbol() + " BUY " + IntegerToString(ticket));
         return(-1);
      }
   }
   else if (OrderType() == OP_SELL)
   {
      if (!OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(ask, dig), 0))
      {
         print("Error#" + IntegerToString(GetLastError()) + " closing " + OrderSymbol() + " BUY " + IntegerToString(ticket));
         return(-1);
      }
   }
   else if (OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
   {
      if (!OrderDelete(OrderTicket()))
      {
         print("Error#" + IntegerToString(GetLastError()) + " deleting " + OrderSymbol() + " PENDING BUY " + IntegerToString(ticket));
         return(-1);
      }
   }
   else if (OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
   {
      if (!OrderDelete(OrderTicket()))
      {
         print("Error#" + IntegerToString(GetLastError()) + " deleting " + OrderSymbol() + " PENDING SELL " + IntegerToString(ticket));
         return(-1);
      }
   }
   
   Alert(OrderSymbol() + " close order #" + IntegerToString(ticket) + " OK!");
   return(0);
}

int closeAll(bool All)
{
   int error = 0, total = OrdersTotal() - 1;
   for (int pos = total; pos >= 0; pos--)
   {
      if (!OrderSelect(pos, SELECT_BY_POS, MODE_TRADES))
      {
         print("OrderSelect error # " + IntegerToString(GetLastError()));
         continue;
      }
      
      if (StringFind(OrderComment(), copyName) < 0)
      {
         continue;
      }

      RefreshRates();
		double ask =      MarketInfo(OrderSymbol(), MODE_ASK);
		double bid =      MarketInfo(OrderSymbol(), MODE_BID);
		int    dig = (int)MarketInfo(OrderSymbol(), MODE_DIGITS);
      
      if (OrderType() == OP_BUY && All)
      {
         if (!OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(bid, dig), 0, Blue))
         {
            Alert("Error closing BUY " + OrderSymbol() + " #" + IntegerToString(GetLastError()));
            error -= 1;
         }
         else
         {
            Alert(OrderSymbol() + " close order #" + IntegerToString(OrderTicket()) + " OK!");
         }
      }
      else if (OrderType() == OP_SELL && All)
      {
         if (!OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(ask, dig), 0))
         {
            Alert("Error closing SELL " + OrderSymbol() + " #" + IntegerToString(GetLastError()));
            error -= 1;
         }
         else
         {
            Alert(OrderSymbol() + " close order #" + IntegerToString(OrderTicket()) + " OK!");
         }
      }
      else if (OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
      {
         if (!OrderDelete(OrderTicket()))
         {
            Alert("Error closing PENDING buy " + OrderSymbol() + " #" + IntegerToString(GetLastError()));
            error -= 1;
         }
         else
         {
            Alert(OrderSymbol() + " close order #" + IntegerToString(OrderTicket()) + " OK!");
         }
      }
      else if (OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
      {
         if (!OrderDelete(OrderTicket()))
         {
            Alert("Error closing PENDING sell " + OrderSymbol() + " #" + IntegerToString(GetLastError()));
            error -= 1;
         }
         else
         {
            Alert(OrderSymbol() + " close order #" + IntegerToString(OrderTicket()) + " OK!");
         }
      }
   }

   return(error);
}

//+------------------------------------------------------------------+