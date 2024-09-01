return {
    Switches = {
        {
            placeId = 1,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.EnableAnchor,
            param = 2,
        },
        {
            placeId = 3,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.EnableAnchor,
            param = 4,
            autoReboot = false,
        },
        {
            placeId = 5,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.EnableSwitch,
            param = 3,
        },
        {
            placeId = 10,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.RaiseTower,
            param = 11,
        },
        {
            placeId = 13,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.RaiseTower,
            param = 12,
        },
        {
            placeId = 20,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.RaiseTower,
            param = 900200,
        },
        {
            placeId = 21,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.RaiseTower,
            param = 900201,
        },
        {
            placeId = 22,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.RaiseTower,
            param = 900202,
        },
        {
            placeId = 23,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.RaiseTower,
            param = 900200,
        },
        {
            placeId = 24,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.RaiseTower,
            param = 900201,
        },
        {
            placeId = 25,
            agent = nil,
            object = nil, ---self,
            func = nil, ---self.RaiseTower,
            param = 900202,
        },
    },
    Anchors = {
        {
            placeId = 2,
            agent = nil,
            defaultEnable = false,
            type = 23,
        },
        {
            placeId = 4,
            agent = nil,
            defaultEnable = false,
            type = 24,
        },
    },
    Towers = {
        {
            placeId = 11,
            agent = nil,
            effectPlayer = 1011,
            type = 12,
            defaultRaise = false,
        },
        {
            placeId = 12,
            agent = nil,
            effectPlayer = 1012,
            type = 13,
            defaultRaise = false,
        },
    }
}