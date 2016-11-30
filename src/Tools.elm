module Tools exposing (..)

import Authenticator.Model
import Browse
import Constants
import Hop.Types
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import I18n exposing (getImageUrlOrOgpLogo, getName)
import Requests exposing (..)
import Routes exposing (getSearchQuery, ToolsNestedRoute(..))
import Set exposing (Set)
import Task
import Tool.View
import Types exposing (..)
import Views exposing (viewWebData)
import WebData exposing (..)


-- MODEL


type Model
    = Tools
        (WebData
            { examplesCount : Int
            , organizationsCount : Int
            , tools : DataIdsBody
            }
        )
    | Tool (WebData DataIdBody)


init : Model
init =
    Tools NotAsked



-- ROUTING


urlUpdate : ( ToolsNestedRoute, Hop.Types.Location ) -> Model -> ( Model, Cmd Msg )
urlUpdate ( route, location ) model =
    let
        searchQuery =
            getSearchQuery location
    in
        case route of
            ToolRoute toolId ->
                ( model, loadOne toolId )

            ToolsIndexRoute ->
                ( model, loadAll searchQuery )



-- UPDATE


type ExternalMsg
    = Navigate String


type InternalMsg
    = Error Http.Error
    | LoadAll String
    | LoadOne String
    | LoadedAll ( DataIdsBody, DataIdsBody, DataIdsBody )
    | LoadedOne DataIdBody


type Msg
    = ForParent ExternalMsg
    | ForSelf InternalMsg


type alias MsgTranslation parentMsg =
    { onInternalMsg : InternalMsg -> parentMsg
    , onNavigate : String -> parentMsg
    }


type alias MsgTranslator parentMsg =
    Msg -> parentMsg


loadAll : String -> Cmd Msg
loadAll searchQuery =
    Task.perform (\_ -> Debug.crash "") (\_ -> ForSelf (LoadAll searchQuery)) (Task.succeed "")


loadOne : String -> Cmd Msg
loadOne id =
    Task.perform (\_ -> Debug.crash "") (\_ -> ForSelf (LoadOne id)) (Task.succeed "")


navigate : String -> Msg
navigate path =
    ForParent (Navigate path)


translateMsg : MsgTranslation parentMsg -> MsgTranslator parentMsg
translateMsg { onInternalMsg, onNavigate } msg =
    case msg of
        ForParent (Navigate path) ->
            onNavigate path

        ForSelf internalMsg ->
            onInternalMsg internalMsg


update :
    InternalMsg
    -> Model
    -> Maybe Authenticator.Model.Authentication
    -> I18n.Language
    -> (DocumentMetatags -> Cmd Msg)
    -> ( Model, Cmd Msg )
update msg model authenticationMaybe language setDocumentMetatags =
    case msg of
        Error err ->
            let
                _ =
                    Debug.log "Tools Error" err

                model' =
                    case model of
                        Tool _ ->
                            Tool (Failure err)

                        Tools _ ->
                            Tools (Failure err)
            in
                ( model', Cmd.none )

        LoadAll searchQuery ->
            let
                loadingStatus =
                    Loading
                        (case model of
                            Tool _ ->
                                Nothing

                            Tools webData ->
                                getData webData
                        )

                model' =
                    Tools (Data loadingStatus)

                cmd =
                    Cmd.map ForSelf
                        (Task.perform
                            Error
                            LoadedAll
                            (Task.map3 (,,)
                                (newTaskGetExamples authenticationMaybe searchQuery "1" Set.empty)
                                (newTaskGetOrganizations authenticationMaybe searchQuery "1" Set.empty)
                                (newTaskGetTools authenticationMaybe searchQuery "" Set.empty)
                            )
                        )
            in
                ( model', cmd )

        LoadOne toolId ->
            let
                model' =
                    case model of
                        Tool webData ->
                            Tool (Data (Loading (getData webData)))

                        Tools _ ->
                            Tool (Data (Loading Nothing))

                cmd =
                    Task.perform Error LoadedOne (newTaskGetTool authenticationMaybe toolId)
                        |> Cmd.map ForSelf
            in
                ( model', cmd )

        LoadedAll ( examples, organizations, tools ) ->
            let
                model' =
                    Tools
                        (Data
                            (Loaded
                                { examplesCount = examples.count
                                , organizationsCount = organizations.count
                                , tools = tools
                                }
                            )
                        )

                cmd =
                    setDocumentMetatags
                        { title = I18n.translate language (I18n.Tool I18n.Plural)
                        , imageUrl = Constants.logoUrl
                        }
            in
                ( model', cmd )

        LoadedOne body ->
            let
                cmd =
                    setDocumentMetatags
                        { title = getName language body.data.id body.data.cards body.data.values
                        , imageUrl = getImageUrlOrOgpLogo language body.data.id body.data.cards body.data.values
                        }
            in
                ( Tool (Data (Loaded body)), cmd )



-- VIEW


view : Maybe Authenticator.Model.Authentication -> Model -> String -> I18n.Language -> List (Html Msg)
view authenticationMaybe model searchQuery language =
    case model of
        Tool webData ->
            [ div [ class "row section" ]
                [ div [ class "container" ]
                    (viewWebData
                        language
                        (\loadingStatus -> [ Tool.View.root navigate language loadingStatus ])
                        webData
                    )
                ]
            ]

        Tools webData ->
            viewWebData
                language
                (\loadingStatus ->
                    let
                        counts =
                            getLoadingStatusData loadingStatus
                                |> Maybe.map
                                    (\loadingStatus ->
                                        { examples = loadingStatus.examplesCount
                                        , organizations = loadingStatus.organizationsCount
                                        , tools = loadingStatus.tools.count
                                        }
                                    )
                    in
                        Browse.view
                            Types.Tool
                            counts
                            navigate
                            searchQuery
                            language
                            (mapLoadingStatus .tools loadingStatus)
                )
                webData
