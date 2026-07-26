package rs.pcelinjak.resource;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import rs.pcelinjak.dto.SyncDtos;
import rs.pcelinjak.entity.Apiary;
import rs.pcelinjak.entity.Hive;
import rs.pcelinjak.entity.User;

import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Path("/api/export")
@Produces(MediaType.APPLICATION_JSON)
public class ExportResource {

    @GET
    @Path("/hive-codes")
    public SyncDtos.HiveCodesResponse hiveCodes(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        User user = User.findById(userId);

        Map<String, Apiary> apiaries = new HashMap<>();
        for (Apiary a : Apiary.<Apiary>list("userId = ?1 and dateDeleted is null", userId)) {
            apiaries.put(a.uuid, a);
        }

        SyncDtos.HiveCodesResponse res = new SyncDtos.HiveCodesResponse();
        if (user != null) {
            res.ownerName = user.name;
            res.ownerEmail = user.email;
            res.ownerPhone = user.phone;
        }

        List<Hive> hives = Hive.<Hive>list("userId = ?1 and dateDeleted is null", userId);
        hives.sort(Comparator.comparingInt((Hive h) -> {
            Apiary a = apiaries.get(h.apiaryUuid);
            return a != null ? a.workNumber : 0;
        }).thenComparingInt(h -> h.orderNumber));

        for (Hive h : hives) {
            SyncDtos.HiveCodeItem item = new SyncDtos.HiveCodeItem();
            item.barcode = h.barcode;
            item.orderNumber = h.orderNumber;
            item.hiveType = h.hiveType;
            Apiary a = apiaries.get(h.apiaryUuid);
            if (a != null) {
                item.apiaryName = a.name;
                item.workNumber = a.workNumber;
            }
            res.codes.add(item);
        }
        return res;
    }
}
