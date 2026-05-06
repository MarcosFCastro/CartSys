object RptPedido: TRptPedido
  OldCreateOrder = False
  Left = 0
  Top = 0
  Height = 300
  Width = 640
  object QryCabecalho: TFDQuery
    Active = False
    Left = 40
    Top = 40
  end
  object DSCabecalho: TDataSource
    DataSet = QryCabecalho
    Left = 160
    Top = 40
  end
  object PipeCabecalho: TppDBPipeline
    DataSource = DSCabecalho
    Left = 280
    Top = 40
  end
  object QryItens: TFDQuery
    Active = False
    Left = 40
    Top = 120
  end
  object DSItens: TDataSource
    DataSet = QryItens
    Left = 160
    Top = 120
  end
  object PipeItens: TppDBPipeline
    DataSource = DSItens
    Left = 280
    Top = 120
  end
  object Report: TppReport
    Left = 400
    Top = 40
  end
end
