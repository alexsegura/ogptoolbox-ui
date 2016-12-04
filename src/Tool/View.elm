module Tool.View exposing (..)

import Browse
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Helpers exposing (aForPath, aIfIsUrl)
import I18n exposing (getImageScreenshotUrl, getImageUrl, getManyStrings, getOneString, getSubTypes)
import Routes
import String
import Tool.Sidebar as Sidebar
import Types exposing (..)
import Views exposing (viewLoading)
import WebData exposing (LoadingStatus(..))


root : (String -> msg) -> I18n.Language -> LoadingStatus DataIdBody -> Html msg
root navigate language loadingStatus =
    case loadingStatus of
        Loading body ->
            case body of
                Nothing ->
                    viewLoading language

                Just body ->
                    viewCard navigate language body

        Loaded body ->
            viewCard navigate language body


viewCard : (String -> msg) -> I18n.Language -> DataIdBody -> Html msg
viewCard navigate language body =
    let
        cards =
            body.data.cards

        values =
            body.data.values
    in
        case Dict.get body.data.id cards of
            Nothing ->
                text "Error: the card was not found."

            Just card ->
                let
                    container =
                        div [ class "container" ]
                            [ div
                                [ class "row" ]
                                [ Sidebar.root language card values
                                , viewCardContent navigate language card cards values
                                ]
                            ]
                in
                    case getImageScreenshotUrl language "" card values of
                        Just url ->
                            div []
                                [ div [ class "banner screenshot" ]
                                    [ div [ class "row " ]
                                        [ div [ class "col-md-12 text-center" ]
                                            [ img [ src url ] [] ]
                                        ]
                                    ]
                                , div [ class "row pull-screenshot" ]
                                    [ div [ class "container" ]
                                        [-- div [ class "row" ]
                                         -- [ div [ class "col-xs-12" ]
                                         --     [ ol [ class "breadcrumb" ]
                                         --         [ li []
                                         --             [ a [ href "#" ]
                                         --                 [ text "Home" ]
                                         --             ]
                                         --         , li []
                                         --             [ a [ href "#" ]
                                         --                 [ text "Library" ]
                                         --             ]
                                         --         , li [ class "active" ]
                                         --             [ text "Data" ]
                                         --         ]
                                         --     ]
                                         -- ]
                                        ]
                                    ]
                                , div [ class "row section push-screenshot" ]
                                    [ container ]
                                ]

                        Nothing ->
                            div [ class "row section" ]
                                [ container ]


viewCardContent : (String -> msg) -> I18n.Language -> Card -> Dict String Card -> Dict String Value -> Html msg
viewCardContent navigate language card cards values =
    let
        bestOf keys =
            let
                count =
                    List.length (getManyStrings language keys card values)
            in
                if count == 1 then
                    text ""
                else
                    text (I18n.translate language (I18n.BestOf count))
    in
        div
            [ classList
                [ ( "col-md-9 content content-right", True )
                , ( "push-screenshot2"
                  , case getImageScreenshotUrl language "" card values of
                        Nothing ->
                            False

                        Just _ ->
                            True
                  )
                ]
            ]
            [ div [ class "row" ]
                [ div [ class "col-xs-12" ]
                    [ h1 []
                        [ text (getName language card values)
                        , small []
                            [ text (getSubTypes language card values |> String.join ", ") ]
                        ]
                    ]
                ]
            , div [ class "row" ]
                [ div [ class "col-xs-12" ]
                    (case getManyStrings language typeKeys card values of
                        [] ->
                            [ button [ class "call-add" ] [ text "+ add a category" ] ]

                        xs ->
                            List.map
                                (\str -> span [ class "label label-default label-tag label-maintag" ] [ text str ])
                                xs
                    )
                ]
            , div [ class "row" ]
                [ div [ class "col-xs-12" ]
                    (([ div [ class "panel panel-default" ]
                            (let
                                panelTitle =
                                    div [ class "col-xs-8 text-left" ]
                                        [ h3 [ class "panel-title" ]
                                            [ text (I18n.translate language I18n.About) ]
                                        ]
                             in
                                case getOneString language descriptionKeys card values of
                                    Nothing ->
                                        [ div [ class "panel-heading" ]
                                            [ div [ class "row" ]
                                                [ panelTitle ]
                                            ]
                                        , div [ class "panel-body" ]
                                            [ div [ class "call-container" ]
                                                [ p [] [ text "No description for this tool yet." ]
                                                , button [ class "button call-add" ] [ text "+ Add a description" ]
                                                ]
                                            ]
                                        ]

                                    Just description ->
                                        [ div [ class "panel-heading" ]
                                            [ div [ class "row" ]
                                                [ panelTitle
                                                , div [ class "col-xs-4 text-right up7" ]
                                                    [ a [ class "show-more" ]
                                                        [ bestOf descriptionKeys ]
                                                    , button
                                                        [ class "btn btn-default btn-xs btn-action"
                                                        , attribute "data-target" "#edit-content"
                                                        , attribute "data-toggle" "modal"
                                                        , type' "button"
                                                        ]
                                                        [ text "Edit" ]
                                                    ]
                                                ]
                                            ]
                                        , div [ class "panel-body" ]
                                            [ text description ]
                                        ]
                            )
                      ]
                     )
                        ++ [ div [ class "panel panel-default panel-collapse up20" ]
                                [ div
                                    [ attribute "aria-controls" "collapseTwo"
                                    , attribute "aria-expanded" "false"
                                    , attribute "data-parent" "#accordion"
                                    , attribute "data-target" "#collapseTwo"
                                    , attribute "data-toggle" "collapse"
                                    , attribute "role" "tab"
                                    , class "panel-heading"
                                    , id "headingTwo"
                                    ]
                                    [ div [ class "row" ]
                                        [ div [ class "col-xs-8 text-left" ]
                                            [ h3 [ class "panel-title" ]
                                                [ text (I18n.translate language I18n.AdditionalInformations) ]
                                            ]
                                        , div [ class "col-xs-4 text-right" ]
                                            [ a [ class "show-more pull-right" ]
                                                [ text ("Show " ++ (card.properties |> Dict.size |> toString) ++ " more")
                                                , span [ class "glyphicon glyphicon-menu-down" ] []
                                                ]
                                            ]
                                        ]
                                    ]
                                , div
                                    [ attribute "aria-labelledby" "headingTwo"
                                    , classList
                                        [ ( "panel-collapse", True )
                                        , ( "collapse", True )
                                        ]
                                    , id "collapseTwo"
                                    , attribute "role" "tabpanel"
                                    ]
                                    [ div [ class "panel-body nomargin" ]
                                        [ table [ class "table table-striped" ]
                                            [ tbody []
                                                (card.properties
                                                    |> Dict.map
                                                        (\propertyKey valueId ->
                                                            case Dict.get valueId values of
                                                                Nothing ->
                                                                    text ("Error: value not found for ID: " ++ valueId)

                                                                Just value ->
                                                                    tr []
                                                                        [ th [ scope "row" ]
                                                                            [ case Dict.get propertyKey values of
                                                                                Nothing ->
                                                                                    text
                                                                                        ("Error: value not found for ID: "
                                                                                            ++ propertyKey
                                                                                        )

                                                                                Just value ->
                                                                                    viewValueValue
                                                                                        language
                                                                                        navigate
                                                                                        cards
                                                                                        values
                                                                                        value.value
                                                                            ]
                                                                        , td []
                                                                            [ viewValueValue
                                                                                language
                                                                                navigate
                                                                                cards
                                                                                values
                                                                                value.value
                                                                            ]
                                                                        ]
                                                        )
                                                    |> Dict.values
                                                )
                                            ]
                                        ]
                                    ]
                                ]
                           , div [ class "panel panel-default" ]
                                [ div [ class "panel-heading" ]
                                    [ div [ class "row" ]
                                        [ div [ class "col-xs-8 text-left" ]
                                            [ h3 [ class "panel-title" ]
                                                [ text (I18n.translate language I18n.UsedFor) ]
                                            ]
                                        ]
                                    ]
                                , div [ class "panel-body" ]
                                    [ case Dict.get "type:software" card.references of
                                        Nothing ->
                                            div [ class "call-container" ]
                                                [ p [] [ text "No use case listed for this tool yet." ]
                                                , button [ class "button call-add" ] [ text "+ Add a use case" ]
                                                ]

                                        Just cardIds ->
                                            div [ class "row list" ]
                                                [ div [ class "col-xs-12" ]
                                                    (List.filterMap
                                                        (\cardId ->
                                                            Dict.get cardId cards
                                                                |> Maybe.map
                                                                    (Browse.viewCardListItem
                                                                        navigate
                                                                        language
                                                                        values
                                                                    )
                                                        )
                                                        cardIds
                                                    )
                                                ]
                                    ]
                                ]
                           , div [ class "panel panel-default" ]
                                [ div [ class "panel-heading" ]
                                    [ div [ class "row" ]
                                        [ div [ class "col-xs-8 text-left" ]
                                            [ h3 [ class "panel-title" ]
                                                [ text (I18n.translate language I18n.UsedBy) ]
                                            ]
                                        , div [ class "col-xs-4 text-right up7" ]
                                            [ a [ class "show-more" ]
                                                [ bestOf usedByKeys ]
                                            , button [ class "btn btn-default btn-xs btn-action", type' "button" ]
                                                [ text "Add" ]
                                            ]
                                        ]
                                    ]
                                  -- , div [ class "panel-body" ]
                                  --     [ div [ class "row" ]
                                  --         ((case getManyStrings language usedByKeys card of
                                  --             [] ->
                                  --                 [ text "TODO call-to-action" ]
                                  --             targetIds ->
                                  --                 targetIds
                                  --                     |> List.map
                                  --                         (\targetId ->
                                  --                             viewCardReferenceAsThumbnail navigate statements targetId
                                  --                         )
                                  --                     |> List.append (viewShowMore (List.length targetIds))
                                  --          )
                                  --         )
                                  --     ]
                                ]
                           ]
                    )
                ]
            ]


viewShowMore : number -> List (Html msg)
viewShowMore count =
    if count > 20 then
        -- TODO Do not hardcode limit
        [ div [ class "col-sm-12 text-center" ]
            [ a [ class "show-more" ]
                [ text ("Show all " ++ (toString count))
                , span [ class "glyphicon glyphicon-menu-down" ]
                    []
                ]
            ]
        ]
    else
        []


viewValueValue : I18n.Language -> (String -> msg) -> Dict String Card -> Dict String Value -> ValueType -> Html msg
viewValueValue language navigate cards values value =
    case value of
        StringValue str ->
            aIfIsUrl [] str

        WrongValue str schemaId ->
            div []
                [ p [ style [ ( "color", "red" ) ] ] [ text "Wrong value!" ]
                , pre [] [ text str ]
                , p [] [ text ("schemaId: " ++ schemaId) ]
                ]

        LocalizedStringValue values ->
            dl []
                (values
                    |> Dict.toList
                    |> List.concatMap
                        (\( languageCode, childValue ) ->
                            [ dt [] [ text languageCode ]
                            , dd [] [ aIfIsUrl [] childValue ]
                            ]
                        )
                )

        NumberValue float ->
            text (toString float)

        ArrayValue childValues ->
            ul [ class "list-unstyled" ]
                (List.map
                    (\childValue -> li [] [ viewValueValue language navigate cards values childValue ])
                    childValues
                )

        BijectiveCardReferenceValue { targetId } ->
            case Dict.get targetId cards of
                Nothing ->
                    text ("Error: target card not found for ID: " ++ targetId)

                Just card ->
                    let
                        linkText =
                            case getOneString language nameKeys card values of
                                Nothing ->
                                    targetId

                                Just name ->
                                    name

                        urlPath =
                            Routes.urlPathForCard card
                    in
                        aForPath navigate
                            urlPath
                            []
                            [ text linkText ]

        ReferenceValue propertyKey ->
            case Dict.get propertyKey values of
                Nothing ->
                    text ("Error: referenced value not found for propertyKey: " ++ propertyKey)

                Just subValue ->
                    viewValueValue language navigate cards values subValue.value
