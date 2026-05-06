object FrmPrincipal: TFrmPrincipal
  Left = 100
  Top = 100
  Caption = 'CartSys - ERP Vendas'
  ClientHeight = 553
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu
  WindowState = wsNormal
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnCloseQuery = FormCloseQuery
  TextHeight = 15
  object StatusBar: TStatusBar
    Left = 0
    Top = 530
    Width = 900
    Height = 23
    Align = alBottom
    Panels = <>
    SimplePanel = True
    SimpleText = 'Pronto.'
  end
  object MainMenu: TMainMenu
    Left = 840
    Top = 8
    object mnuCadastros: TMenuItem
      Caption = '&Cadastros'
      object mnuClientes: TMenuItem
        Caption = '&Clientes'
        OnClick = mnuClientesClick
      end
      object mnuProdutos: TMenuItem
        Caption = '&Produtos'
        OnClick = mnuProdutosClick
      end
      object mnuVendas: TMenuItem
        Caption = '&Vendas'
        OnClick = mnuVendasClick
      end
    end
    object mnuIntegracao: TMenuItem
      Caption = '&Integra'#231#227'o'
      object mnuLogIntegracao: TMenuItem
        Caption = '&Log de Integra'#231#227'o'
        OnClick = mnuLogIntegracaoClick
      end
    end
    object mnuSistema: TMenuItem
      Caption = 'Si&stema'
      object mnuSair: TMenuItem
        Caption = 'Sa&ir'
        OnClick = mnuSairClick
      end
    end
  end
end
