module Requests exposing (..)

import Authenticator.Model
import Configuration exposing (apiUrl)
import Decoders exposing (..)
import Dict exposing (Dict)
import Http
import I18n
import Json.Decode as Decode
import Json.Encode as Encode
import String
import Types exposing (..)
import Task exposing (Task)


activateUser : String -> String -> Task Http.Error UserBody
activateUser userId authorization =
    Http.fromJson userBodyDecoder
        (Http.send Http.defaultSettings
            { verb = "GET"
            , url = apiUrl ++ "users/" ++ userId ++ "/activate?authorization=" ++ authorization
            , headers = [ ( "Accept", "application/json" ) ]
            , body = Http.empty
            }
        )


authenticationHeaders : Maybe Authenticator.Model.Authentication -> List ( String, String )
authenticationHeaders authentication =
    case authentication of
        Just authentication ->
            [ ( "Retruco-API-Key", authentication.apiKey ) ]

        Nothing ->
            []


getCard : Maybe Authenticator.Model.Authentication -> String -> Task Http.Error DataIdBody
getCard authentication cardId =
    Http.fromJson dataIdBodyDecoder
        (Http.send Http.defaultSettings
            { verb = "GET"
            , url = apiUrl ++ "objects/" ++ cardId ++ "?show=references&show=values&depth=2"
            , headers = ( "Accept", "application/json" ) :: authenticationHeaders authentication
            , body = Http.empty
            }
        )


getCards :
    Maybe Authenticator.Model.Authentication
    -> String
    -> Maybe Int
    -> List String
    -> List String
    -> Task Http.Error DataIdsBody
getCards authentication searchQuery limit tagIds cardTypes =
    Http.fromJson dataIdsBodyDecoder
        (Http.send Http.defaultSettings
            { verb = "GET"
            , url =
                apiUrl
                    ++ "cards?"
                    ++ (List.map (\cardType -> "type=" ++ cardType) cardTypes
                            ++ (([ Just "show=values"
                                 , Just "depth=1"
                                 , (if String.isEmpty searchQuery then
                                        Nothing
                                    else
                                        Just ("term=" ++ searchQuery)
                                   )
                                 , limit |> Maybe.map (\limit -> "limit=" ++ (toString limit))
                                 ]
                                    |> List.filterMap identity
                                )
                                    ++ (tagIds
                                            |> List.filter (\s -> not (String.isEmpty s))
                                            |> List.map (\tagId -> "tag=" ++ tagId)
                                       )
                               )
                            |> String.join "&"
                       )
            , headers = ( "Accept", "application/json" ) :: authenticationHeaders authentication
            , body = Http.empty
            }
        )


getObjectProperties : Maybe Authenticator.Model.Authentication -> String -> String -> Task Http.Error DataIdsBody
getObjectProperties authentication objectId keyId =
    Http.fromJson dataIdsBodyDecoder
        (Http.send Http.defaultSettings
            { verb = "GET"
            , url = apiUrl ++ "objects/" ++ objectId ++ "/properties/" ++ keyId ++ "?show=ballots&show=values&depth=1"
            , headers = ( "Accept", "application/json" ) :: authenticationHeaders authentication
            , body = Http.empty
            }
        )


getTagsPopularity : List String -> Task Http.Error PopularTagsData
getTagsPopularity tagIds =
    let
        url =
            apiUrl
                ++ "cards/tags-popularity?type=use-case&"
                ++ (tagIds
                        |> List.filter (\s -> not (String.isEmpty s))
                        |> List.map (\tagId -> "tag=" ++ tagId)
                        |> String.join "&"
                   )
    in
        Http.fromJson popularTagsDataDecoder
            (Http.send Http.defaultSettings
                { verb = "GET"
                , url = url
                , headers = [ ( "Accept", "application/json" ) ]
                , body = Http.empty
                }
            )


postCardsEasy :
    Maybe Authenticator.Model.Authentication
    -> Dict String String
    -> I18n.Language
    -> Task Http.Error DataIdBody
postCardsEasy authentication fields language =
    let
        body =
            Encode.object
                [ ( "language", Encode.string (I18n.iso639_1FromLanguage language) )
                , ( "schemas"
                  , Encode.object
                        [ ( "Description", Encode.string "schema:string" )
                        , ( "Download", Encode.string "schema:uri" )
                        , ( "Logo", Encode.string "schema:uri" )
                        , ( "Name", Encode.string "schema:string" )
                        , ( "Types", Encode.string "schema:type-reference" )
                        , ( "Website", Encode.string "schema:uri" )
                        ]
                  )
                , ( "values"
                  , Encode.object
                        (fields
                            |> Dict.toList
                            |> List.map (\( name, value ) -> ( name, Encode.string value ))
                        )
                  )
                , ( "widgets", Encode.object [] )
                ]
                |> Encode.encode 2
                |> Http.string
    in
        Http.fromJson dataIdBodyDecoder
            (Http.send Http.defaultSettings
                { verb = "POST"
                , url = apiUrl ++ "cards/easy"
                , headers =
                    [ ( "Accept", "application/json" )
                    , ( "Content-Type", "application/json" )
                    ]
                        ++ authenticationHeaders authentication
                , body = body
                }
            )


postProperty : Maybe Authenticator.Model.Authentication -> String -> String -> String -> Task Http.Error DataIdBody
postProperty authentication objectId keyId valueId =
    Http.fromJson dataIdBodyDecoder
        (Http.send Http.defaultSettings
            { verb = "POST"
            , url = apiUrl ++ "properties?show=ballots&show=values&depth=1"
            , headers =
                [ ( "Accept", "application/json" )
                , ( "Content-Type", "application/json" )
                ]
                    ++ authenticationHeaders authentication
            , body =
                Encode.object
                    [ ( "keyId", Encode.string keyId )
                    , ( "objectId", Encode.string objectId )
                    , ( "valueId", Encode.string valueId )
                    ]
                    |> Encode.encode 2
                    |> Http.string
            }
        )


postRating : Maybe Authenticator.Model.Authentication -> String -> Int -> Task Http.Error DataIdBody
postRating authentication propertyId rating =
    Http.fromJson dataIdBodyDecoder
        (Http.send Http.defaultSettings
            { verb = "POST"
            , url = apiUrl ++ "statements/" ++ propertyId ++ "/rating"
            , headers =
                [ ( "Accept", "application/json" )
                , ( "Content-Type", "application/json" )
                ]
                    ++ authenticationHeaders authentication
            , body = Encode.object [ ( "rating", Encode.int rating ) ] |> Encode.encode 2 |> Http.string
            }
        )


postUploadImage : Maybe Authenticator.Model.Authentication -> String -> Task Http.Error String
postUploadImage authentication contents =
    Http.fromJson Decode.string
        (Http.send Http.defaultSettings
            { verb = "POST"
            , url = apiUrl ++ "uploads/images"
            , headers = ( "Accept", "application/json" ) :: authenticationHeaders authentication
            , body = Http.multipart [ Http.stringData "file" contents ]
            }
        )


postValue : Maybe Authenticator.Model.Authentication -> Field -> Task Http.Error DataIdBody
postValue authentication field =
    let
        ( schemaId, widgetId, encodedValue ) =
            case field of
                InputTextField string ->
                    ( "schema:string", "widget:input-text", Encode.string string )

                TextareaField string ->
                    ( "schema:string", "widget:textarea", Encode.string string )

                InputNumberField float ->
                    ( "schema:number", "widget:input-number", Encode.float float )

                BooleanField bool ->
                    ( "schema:boolean", "widget:input-checkbox", Encode.bool bool )

                InputEmailField string ->
                    ( "schema:email", "widget:input-email", Encode.string string )

                InputUrlField string ->
                    ( "schema:uri", "widget:input-url", Encode.string string )

                ImageField string ->
                    ( "schema:uri", "widget:image", Encode.string string )

                CardIdField string ->
                    ( "schema:card-id", "widget:autocomplete", Encode.string string )
    in
        Http.fromJson dataIdBodyDecoder
            (Http.send Http.defaultSettings
                { verb = "POST"
                , url = apiUrl ++ "values"
                , headers =
                    [ ( "Accept", "application/json" )
                    , ( "Content-Type", "application/json" )
                    ]
                        ++ authenticationHeaders authentication
                , body =
                    Encode.object
                        [ ( "schema", Encode.string schemaId )
                        , ( "value", encodedValue )
                        , ( "widget", Encode.string widgetId )
                        ]
                        |> Encode.encode 2
                        |> Http.string
                }
            )
