object FrmCadProduto: TFrmCadProduto
  Left = 0
  Top = 0
  Caption = 'Produtos'
  ClientHeight = 480
  ClientWidth = 820
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlFiltro: TPanel
    Left = 0
    Top = 0
    Width = 820
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblFiltro: TLabel
      Left = 8
      Top = 14
      Width = 39
      Height = 15
      Caption = 'Filtrar:'
    end
    object edtFiltro: TEdit
      Left = 56
      Top = 11
      Width = 240
      Height = 23
      TabOrder = 0
      OnChange = edtFiltroChange
    end
  end
  object lvProdutos: TListView
    Left = 0
    Top = 44
    Width = 820
    Height = 392
    Align = alClient
    Columns = <
      item
        Caption = 'C'#243'digo'
        Width = 90
      end
      item
        Caption = 'Descri'#231#227'o'
        Width = 280
      end
      item
        Caption = 'Unidade'
        Width = 80
      end
      item
        Caption = 'Pre'#231'o Unit.'
        Width = 110
      end
      item
        Caption = 'Ativo'
        Width = 50
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
  end
  object pnlBotoes: TPanel
    Left = 0
    Top = 436
    Width = 820
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitTop = 436
    ExplicitWidth = 820
    object btnNovo: TButton
      Left = 8
      Top = 8
      Width = 88
      Height = 28
      Caption = '&Novo'
      TabOrder = 0
      OnClick = btnNovoClick
    end
    object btnEditar: TButton
      Left = 104
      Top = 8
      Width = 88
      Height = 28
      Caption = '&Editar'
      TabOrder = 1
      OnClick = btnEditarClick
    end
    object btnExcluir: TButton
      Left = 200
      Top = 8
      Width = 88
      Height = 28
      Caption = 'E&xcluir'
      TabOrder = 2
      OnClick = btnExcluirClick
    end
    object btnFechar: TButton
      Left = 724
      Top = 8
      Width = 88
      Height = 28
      Anchors = [akTop, akRight]
      Caption = '&Fechar'
      TabOrder = 3
      OnClick = btnFecharClick
    end
  end
end
