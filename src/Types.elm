module Types exposing (..)

import Configuration exposing (apiUrl)
import Dict exposing (Dict)
import String


type alias BijectiveUriReference =
    { targetId : String
    , reverseKeyId : String
    }


type alias Card =
    { createdAt : String
    , deleted : Bool
    , id : String
    , properties : Dict String String
    , rating : Int
    , ratingCount : Int
    , ratingSum : Int
    , subTypes : List String
    , tags : List (Dict String String)
    , type_ : String
    }


type CardType
    = Example
    | Organization
    | Tool


type alias DataId =
    { cards : Dict String Card
    , id : String
    , values : Dict String Value
    }


type alias DataIdBody =
    { data : DataId
    }


type alias DataIds =
    { cards : Dict String Card
    , ids : List String
    , users : Dict String User
    , values : Dict String Value
    }


type alias DataIdsBody =
    { count : Int
    , data : DataIds
    , limit : Int
    , offset : Int
    }


type alias DocumentMetatags =
    { title : String
    , imageUrl : String
    }


type alias PopularTag =
    { count : Float
    , tag : String
    }


type alias User =
    { apiKey : String
    , email : String
    , name : String
    , urlName : String
    }


type alias UserBody =
    { data : User
    }


type alias Value =
    { createdAt : String
    , id : String
    , schemaId : String
    , type_ : String
    , value : ValueType
    , widgetId : String
    }


type ValueType
    = StringValue String
    | LocalizedStringValue (Dict String String)
    | NumberValue Float
    | ArrayValue (List ValueType)
    | BijectiveUriReferenceValue BijectiveUriReference
    | WrongValue String String


imageUrl : String -> String
imageUrl urlPath =
    apiUrl
        ++ (if String.startsWith "/" urlPath then
                String.dropLeft 1 urlPath
            else
                urlPath
           )



-- KEYS


descriptionKeys : List String
descriptionKeys =
    [ "description" ]


imageUrlPathKeys : List String
imageUrlPathKeys =
    [ "logo", "screenshot" ]


licenseKeys : List String
licenseKeys =
    [ "license" ]


nameKeys : List String
nameKeys =
    [ "name" ]


tagKeys : List String
tagKeys =
    [ "tags" ]


typeKeys : List String
typeKeys =
    [ "types" ]


urlKeys : List String
urlKeys =
    [ "website" ]


usedByKeys : List String
usedByKeys =
    [ "used-by" ]



-- CARD TYPES


cardTypesForExample : List String
cardTypesForExample =
    [ "Final Use" ]


cardTypesForOrganization : List String
cardTypesForOrganization =
    [ "Organization" ]


cardTypesForTool : List String
cardTypesForTool =
    [ "Software", "Platform" ]
