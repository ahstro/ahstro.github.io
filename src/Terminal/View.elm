module Terminal.View exposing (terminal)

import Html exposing (Html, input, div, text)
import Html.Attributes exposing (value, id)
import Html.Events exposing (on, onInput, onClick)
import Html.Events.Extra exposing (onEnter)
import Html.CssHelpers
import Json.Decode as Json
import Model exposing (Model)
import Update exposing (Msg(..))
import Terminal.Style as Style
import Constants exposing (terminalInputId, terminalId)
import Regex exposing (regex, HowMany(AtMost))


{ class } =
    Html.CssHelpers.withNamespace Style.namespace


terminal : Model -> Html Msg
terminal model =
    div
        [ class [ Style.Terminal ]
        , onClick FocusTerminalInput
        , handleKeyCombination
        , id terminalId
        ]
        [ div
            [ class [ Style.Output ] ]
            (model.terminalOutput
                |> List.reverse
                |> List.map viewOutput
            )
        , div
            [ class [ Style.Input ] ]
            [ prompt
            , input
                [ onInput SetTerminalInput
                , onEnter RunCommand
                , value model.terminalInput
                , class [ Style.InputInput ]
                , id terminalInputId
                ]
                []
            ]
        ]


viewOutput : String -> Html Msg
viewOutput command =
    div []
        [ div [ class [ Style.OutputLine ] ]
            [ prompt
            , text command
            ]
        , getOutput command
        ]


getOutput : String -> Html Msg
getOutput command =
    let
        ( cmd, tail ) =
            case splitAtFirstWhitespace command of
                cmd :: tail :: _ ->
                    ( cmd, tail )

                cmd :: _ ->
                    ( cmd, "" )

                _ ->
                    ( "", "" )
    in
        case cmd of
            "echo" ->
                text tail

            "hello" ->
                text "hi :)"

            "" ->
                text ""

            _ ->
                text <| "ash: command not found: " ++ command


prompt : Html Msg
prompt =
    div
        [ class [ Style.Prompt ] ]
        [ text "λ" ]


type alias KeyCombination =
    { key : String
    , ctrlKey : Bool
    }


handleKeyCombination : Html.Attribute Msg
handleKeyCombination =
    (Json.map2 KeyCombination
        (Json.field "key" Json.string)
        (Json.field "ctrlKey" Json.bool)
    )
        |> Json.andThen
            (\{ ctrlKey, key } ->
                if ctrlKey then
                    Json.succeed <| getCtrlKeyBinding key
                else
                    Json.succeed <| getKeyBinding key
            )
        |> on "keydown"


getCtrlKeyBinding : String -> Msg
getCtrlKeyBinding key =
    case (String.toLower key) of
        "l" ->
            ClearTerminalOutput

        "u" ->
            ClearTerminalInput

        "p" ->
            ScrollTerminalInputBack

        "n" ->
            ScrollTerminalInputForward

        _ ->
            NoOp


getKeyBinding : String -> Msg
getKeyBinding key =
    case (String.toLower key) of
        "arrowup" ->
            ScrollTerminalInputBack

        "arrowdown" ->
            ScrollTerminalInputForward

        _ ->
            NoOp


splitAtFirstWhitespace : String -> List String
splitAtFirstWhitespace =
    Regex.split (AtMost 1) (regex "\\s+")
