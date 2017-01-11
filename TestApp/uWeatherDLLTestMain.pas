unit uWeatherDLLTestMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Variants, System.Classes, System.TypInfo,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls,
  JD.Weather.Intf, JD.Weather.SuperObject, System.ImageList, Vcl.ImgList,
  Vcl.Menus;

type
  TfrmMain = class(TForm)
    Panel4: TPanel;
    lstServices: TListView;
    lstURLs: TListView;
    GP: TGridPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel5: TPanel;
    Panel3: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    imgLogo: TImage;
    Panel11: TPanel;
    Panel12: TPanel;
    imgList: TImageList;
    lstSupportedInfo: TListView;
    lstSupportedLocationTypes: TListView;
    lstSupportedConditionProps: TListView;
    lstSupportedAlertTypes: TListView;
    lstSupportedForecastSummaryProps: TListView;
    lstSupportedAlertProps: TListView;
    lstSupportedForecastHourlyProps: TListView;
    lstSupportedForecastDailyProps: TListView;
    lstSupportedMaps: TListView;
    lstSupportedUnits: TListView;
    MM: TMainMenu;
    File1: TMenuItem;
    Service1: TMenuItem;
    Refresh1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    EditSettings1: TMenuItem;
    N2: TMenuItem;
    estData1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure lstServicesSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure lstURLsClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FCreateLib: TCreateJDWeather;
    FLib: HMODULE;
    FWeather: IJDWeather;
    procedure ClearInfo;
    procedure WeatherImageToPicture(const G: IWeatherGraphic;
      const P: TPicture);
  public
    procedure LoadServices;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  E: Integer;
begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown:= True;
  {$ENDIF}
  Width:= 1200;
  Height:= 800;
  GP.Align:= alClient;
  imgLogo.Align:= alClient;
  lstURLs.Align:= alClient;
  lstServices.Width:= lstServices.Width + 1;
  GP.Width:= GP.Width + 1;

  lstSupportedInfo.Align:= alClient;
  lstSupportedLocationTypes.Align:= alClient;
  lstSupportedConditionProps.Align:= alClient;
  lstSupportedAlertTypes.Align:= alClient;
  lstSupportedAlertProps.Align:= alClient;
  lstSupportedForecastSummaryProps.Align:= alClient;
  lstSupportedForecastHourlyProps.Align:= alClient;
  lstSupportedForecastDailyProps.Align:= alClient;
  lstSupportedMaps.Align:= alClient;
  lstSupportedUnits.Align:= alClient;

  Show;
  BringToFront;
  Application.ProcessMessages;

  //Load weather library
  FLib:= LoadLibrary('JDWeather.dll');
  if FLib <> 0 then begin
    FCreateLib:= GetProcAddress(FLib, 'CreateJDWeather');
    if Assigned(FCreateLib) then begin
      try
        FWeather:= FCreateLib(ExtractFilePath(ParamStr(0)));
        LoadServices;
      except
        on E: Exception do begin
          raise Exception.Create('Failed to create new instance of "IJDWeather": '+E.Message);
        end;
      end;
    end else begin
      raise Exception.Create('Function "CreateJDWeather" not found!');
    end;
  end else begin
    E:= GetLastError;
    raise Exception.Create('Failed to load library "JDWeather.dll" with error code '+IntToStr(E));
  end;

end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  //
end;

procedure TfrmMain.LoadServices;
var
  X: Integer;
  S: IWeatherService;
  I: TListItem;
begin
  //Displays a list of supported services
  lstServices.Items.Clear;
  for X := 0 to FWeather.Services.Count-1 do begin
    S:= FWeather.Services.Items[X];
    I:= lstServices.Items.Add;
    I.Caption:= S.Caption;
    I.Data:= Pointer(S);
  end;
end;

procedure TfrmMain.WeatherImageToPicture(const G: IWeatherGraphic; const P: TPicture);
var
  S: TStringStream;
  I: TWicImage;
begin
  //Converts an `IWeatherGraphic` interface to a `TPicture`
  S:= TStringStream.Create;
  try
    S.WriteString(G.Base64);
    S.Position:= 0;
    I:= TWicImage.Create;
    try
      I.LoadFromStream(S);
      P.Assign(I);
    finally
      FreeAndNil(I);
    end;
  finally
    FreeAndNil(S);
  end;
end;

procedure TfrmMain.ClearInfo;
begin
  //Clear all service information
  lstURLs.Items.Clear;
  lstSupportedInfo.Items.Clear;
  lstSupportedLocationTypes.Items.Clear;
  lstSupportedConditionProps.Items.Clear;
  lstSupportedAlertTypes.Items.Clear;
  lstSupportedAlertProps.Items.Clear;
  lstSupportedForecastSummaryProps.Items.Clear;
  lstSupportedForecastHourlyProps.Items.Clear;
  lstSupportedForecastDailyProps.Items.Clear;
  lstSupportedMaps.Items.Clear;
  lstSupportedUnits.Items.Clear;
  imgLogo.Picture.Assign(nil);
end;

procedure TfrmMain.lstURLsClick(Sender: TObject);
var
  U: String;
begin
  //Launch url in browser
  if lstURLs.ItemIndex >= 0 then begin
    U:= lstURLs.Selected.SubItems[0];
    ShellExecute(0, 'open', PChar(U), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TfrmMain.lstServicesSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
//Display all supported pieces of selected service
const
  IMG_CHECK = 1;
  IMG_UNCHECK = -1;
var
  S: IWeatherService;
  TInfo, TCond, TLoc, TAlert, TAlertProp, TForSum, TForHour, TForDay, TMaps, TUnits: Integer;
  PInfo, PCond, PLoc, PAlert, PAlertProp, PForSum, PForHour, PForDay, PMaps, PUnits: Single;
  TP: Single;
  WInfo: TWeatherInfoType;
  WLoc: TJDWeatherLocationType;
  WCond: TWeatherConditionsProp;
  WFor: TWeatherForecastProp;
  WAlt: TWeatherAlertType;
  WAlp: TWeatherAlertProp;
  WMap: TWeatherMapType;
  WMaf: TWeatherMapFormat;
  WUni: TWeatherUnits;
  I: TListItem;
  procedure ChkUrl(const N, V: String);
  var
    I: TListItem;
  begin
    if V <> '' then begin
      I:= lstURLs.Items.Add;
      I.Caption:= N;
      I.SubItems.Add(V);
    end;
  end;
begin
  TInfo:= 0;
  TCond:= 0;
  TLoc:= 0;
  TAlert:= 0;
  TAlertProp:= 0;
  TForSum:= 0;
  TForHour:= 0;
  TForDay:= 0;
  TMaps:= 0;
  TUnits:= 0;
  Screen.Cursor:= crHourglass;
  try
    ClearInfo;
    if Selected then begin
      S:= IWeatherService(Item.Data);

      //Display URLs for Service
      ChkUrl('Website', S.URLs.MainURL);
      ChkUrl('API Docs', S.URLs.ApiURL);
      ChkUrl('Register', S.URLs.RegisterURL);
      ChkUrl('Login', S.URLs.LoginURL);
      ChkUrl('Legal', S.URLs.LegalURL);

      //Show supported information types
      lstSupportedInfo.Items.BeginUpdate;
      try
        for WInfo := Low(TWeatherInfoType) to High(TWeatherInfoType) do begin
          I:= lstSupportedInfo.Items.Add;
          I.Caption:= WeatherInfoTypeToStr(WInfo);
          if WInfo in S.Support.SupportedInfo then begin
            Inc(TInfo);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedInfo.Items.EndUpdate;
      end;

      //Show supported location lookup types
      lstSupportedLocationTypes.Items.BeginUpdate;
      try
        for WLoc := Low(TJDWeatherLocationType) to High(TJDWeatherLocationType) do begin
          I:= lstSupportedLocationTypes.Items.Add;
          I.Caption:= WeatherLocationTypeToStr(WLoc);
          if WLoc in S.Support.SupportedLocations then begin
            Inc(TLoc);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedLocationTypes.Items.EndUpdate;
      end;

      //Show supported condition properties
      lstSupportedConditionProps.Items.BeginUpdate;
      try
        for WCond := Low(TWeatherConditionsProp) to High(TWeatherConditionsProp) do begin
          I:= lstSupportedConditionProps.Items.Add;
          I.Caption:= WeatherConditionPropToStr(WCond);
          if WCond in S.Support.SupportedConditionProps then begin
            Inc(TCond);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedConditionProps.Items.EndUpdate;
      end;

      //Display supported forecast summary properties
      lstSupportedForecastSummaryProps.Items.BeginUpdate;
      try
        for WFor := Low(TWeatherForecastProp) to High(TWeatherForecastProp) do begin
          I:= lstSupportedForecastSummaryProps.Items.Add;
          I.Caption:= WeatherForecastPropToStr(WFor);
          if WFor in S.Support.SupportedForecastSummaryProps then begin
            Inc(TForSum);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedForecastSummaryProps.Items.EndUpdate;
      end;

      //Display supported forecast hourly properties
      lstSupportedForecastHourlyProps.Items.BeginUpdate;
      try
        for WFor := Low(TWeatherForecastProp) to High(TWeatherForecastProp) do begin
          I:= lstSupportedForecastHourlyProps.Items.Add;
          I.Caption:= WeatherForecastPropToStr(WFor);
          if WFor in S.Support.SupportedForecastHourlyProps then begin
            Inc(TForHour);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedForecastHourlyProps.Items.EndUpdate;
      end;

      //Display supported forecast daily properties
      lstSupportedForecastDailyProps.Items.BeginUpdate;
      try
        for WFor := Low(TWeatherForecastProp) to High(TWeatherForecastProp) do begin
          I:= lstSupportedForecastDailyProps.Items.Add;
          I.Caption:= WeatherForecastPropToStr(WFor);
          if WFor in S.Support.SupportedForecastDailyProps then begin
            Inc(TForDay);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedForecastDailyProps.Items.EndUpdate;
      end;

      //Display supported alert types
      lstSupportedAlertTypes.Items.BeginUpdate;
      try
        for WAlt := Low(TWeatherAlertType) to High(TWeatherAlertType) do begin
          I:= lstSupportedAlertTypes.Items.Add;
          I.Caption:= WeatherAlertTypeToStr(WAlt);
          if WAlt in S.Support.SupportedAlerts then begin
            Inc(TAlert);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedAlertTypes.Items.EndUpdate;
      end;

      //Display supported alert properties
      lstSupportedAlertProps.Items.BeginUpdate;
      try
        for WAlp := Low(TWeatherAlertProp) to High(TWeatherAlertProp) do begin
          I:= lstSupportedAlertProps.Items.Add;
          I.Caption:= WeatherAlertPropToStr(WAlp);
          if WAlp in S.Support.SupportedAlertProps then begin
            Inc(TAlertProp);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedAlertProps.Items.EndUpdate;
      end;

      //Display supported map types
      lstSupportedMaps.Items.BeginUpdate;
      try
        for WMap := Low(TWeatherMapType) to High(TWeatherMapType) do begin
          I:= lstSupportedMaps.Items.Add;
          I.Caption:= WeatherMapTypeToStr(WMap);
          if WMap in S.Support.SupportedMaps then begin
            Inc(TMaps);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedMaps.Items.EndUpdate;
      end;

      //Display supported map formats
      lstSupportedMaps.Items.BeginUpdate;
      try
        for WMaf := Low(TWeatherMapFormat) to High(TWeatherMapFormat) do begin
          I:= lstSupportedMaps.Items.Add;
          I.Caption:= WeatherMapFormatToStr(WMaf);
          if WMaf in S.Support.SupportedMapFormats then begin
            Inc(TMaps);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedMaps.Items.EndUpdate;
      end;

      //Display supported units of measurement
      lstSupportedUnits.Items.BeginUpdate;
      try
        for WUni := Low(TWeatherUnits) to High(TWeatherUnits) do begin
          I:= lstSupportedUnits.Items.Add;
          I.Caption:= WeatherUnitsToStr(WUni);
          if WUni in S.Support.SupportedUnits then begin
            Inc(TUnits);
            I.ImageIndex:= IMG_CHECK;
          end else begin
            I.ImageIndex:= IMG_UNCHECK;
          end;
        end;
      finally
        lstSupportedUnits.Items.EndUpdate;
      end;

      //Calculate percentage of support for each type of info
      PInfo:= TInfo / (Integer(High(TWeatherInfoType))+1);
      PLoc:= TLoc / (Integer(High(TJDWeatherLocationType))+1);
      PCond:= TCond / (Integer(High(TWeatherConditionsProp))+1);
      PAlert:= TAlert / (Integer(High(TWeatherAlertType))+1);
      PAlertProp:= TAlertProp / (Integer(High(TWeatherAlertProp))+1);
      PForSum:= TForSum / (Integer(High(TWeatherForecastProp))+1);
      PForHour:= TForHour / (Integer(High(TWeatherForecastProp))+1);
      PForDay:= TForDay / (Integer(High(TWeatherForecastProp))+1);
      PMaps:= TMaps / ((Integer(High(TWeatherMapType))+1) + (Integer(High(TWeatherMapFormat))+1));
      PUnits:= TUnits / (Integer(High(TWeatherUnits))+1);

      //Calculate overall average of support percentage for selected service
      TP:=(PInfo + PLoc + PCond + PAlert + PAlertProp + PForSum +
        PForHour + PForDay + PMaps + PUnits) / 10;
      Caption:= 'JD Weather DLL Test - '+S.Caption+' - '+FormatFloat('0.00%', TP*100);

      //Display service company logo
      WeatherImageToPicture(S.GetLogo(ltColor), imgLogo.Picture);

    end else begin
      Caption:= 'JD Weather DLL Test';
    end;

    GP.Width:= GP.Width + 1;

  finally
    Screen.Cursor:= crDefault;
  end;
end;

end.
