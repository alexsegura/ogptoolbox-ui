module Examples.View exposing (..)

import Authenticator.Model
import Browse exposing (ActivePill(..))
import Example
import Examples.Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Views exposing (viewWebData)
import WebData exposing (..)


root : Maybe Authenticator.Model.Authentication -> Model -> String -> List (Html Msg)
root authenticationMaybe model searchQuery =
    case model of
        Example webData ->
            [ div [ class "row section" ]
                [ div [ class "container" ]
                    (viewWebData
                        (\loadingStatus -> [ Example.view navigate loadingStatus ])
                        webData
                    )
                ]
            ]

        Examples.Types.Examples webData ->
            viewWebData
                (\loadingStatus ->
                    let
                        counts =
                            getLoadingStatusData loadingStatus
                                |> Maybe.map
                                    (\loadingStatus ->
                                        { examples = loadingStatus.examples.count
                                        , organizations = loadingStatus.organizationsCount
                                        , tools = loadingStatus.toolsCount
                                        }
                                    )
                    in
                        Browse.view
                            Browse.Examples
                            counts
                            navigate
                            searchQuery
                            (mapLoadingStatus .examples loadingStatus)
                )
                webData
